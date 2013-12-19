//
//  HIDatabaseManager.m
//  Hive
//
//  Created by Jakub Suder on 10.12.13.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HIDatabaseManager.h"

#define CheckError(error) if (error) { HILogError(@"%@", error); [NSApp presentError:(error)]; return nil; }

@interface HIDatabaseManager ()

@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation HIDatabaseManager

+ (HIDatabaseManager *)sharedManager {
    static HIDatabaseManager *_sharedManager = nil;
    static dispatch_once_t oncePredicate;

    if (!_sharedManager) {
        dispatch_once(&oncePredicate, ^{
            _sharedManager = [[self alloc] init];
        });
    }

    return _sharedManager;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (!_managedObjectModel) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Hive" withExtension:@"momd"];
        self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }

    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }

    NSManagedObjectModel *mom = self.managedObjectModel;

    if (!mom) {
        HILogError(@"%@:%@ No model to generate a store from", self.class, NSStringFromSelector(_cmd));
        return nil;
    }

    NSURL *applicationFilesDirectory = [[NSApp delegate] applicationFilesDirectory];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    BOOL isDirectory;
    BOOL exists = [fileManager fileExistsAtPath:applicationFilesDirectory.path isDirectory:&isDirectory];

    if (!exists) {
        [fileManager createDirectoryAtPath:applicationFilesDirectory.path
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];

        CheckError(error);
    } else if (!isDirectory) {
        NSString *failureDescription = [NSString stringWithFormat:
                                        @"Expected a folder to store application data, found a file (%@).",
                                        applicationFilesDirectory.path];

        NSDictionary *dict = @{NSLocalizedDescriptionKey: failureDescription};
        error = [NSError errorWithDomain:@"net.novaproject.DatabaseError" code:101 userInfo:dict];

        CheckError(error);
    }

    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"Hive.storedata"];

    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];

    NSDictionary *storeOptions = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                                   NSInferMappingModelAutomaticallyOption: @YES};

    NSPersistentStore *sqliteStore = [coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                               configuration:nil
                                                                         URL:url
                                                                     options:storeOptions
                                                                       error:&error];

    if (!sqliteStore) {
        HILogWarn(@"Can't open SQLite store: %@", error);

        // see if it isn't the old xml version
        NSPersistentStore *xmlStore = [coordinator addPersistentStoreWithType:NSXMLStoreType
                                                                configuration:nil
                                                                          URL:url
                                                                      options:nil
                                                                        error:&error];

        if (xmlStore) {
            NSPersistentStore *sqliteStore = [self migrateXMLStoreToSqlite:xmlStore inCoordinator:coordinator];

            if (sqliteStore) {
                // xml store had problems with saving all transactions so rebuild the list in case some were lost
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[BCClient sharedClient] rebuildTransactionsList];
                });
            } else {
                return nil;
            }
        } else {
            CheckError(error);
        }
    }

    _persistentStoreCoordinator = coordinator;
    return _persistentStoreCoordinator;
}

- (void)deletePersistentStoreAtURL:(NSURL *)URL error:(NSError **)error {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    for (NSString *suffix in @[@"", @"-journal", @"-wal", @"-shm"]) {
        NSString *path = [URL.path stringByAppendingString:suffix];

        if ([fileManager fileExistsAtPath:path]) {
            [fileManager removeItemAtPath:path error:error];

            if (error && *error) {
                HILogError(@"Can't delete persistent store at %@: %@", path, *error);
                return;
            }
        }
    }
}

- (NSPersistentStore *)migrateXMLStoreToSqlite:(NSPersistentStore *)xmlStore
                                 inCoordinator:(NSPersistentStoreCoordinator *)coordinator {
    HILogInfo(@"Migrating XML store to SQLite");

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSURL *url = xmlStore.URL;
    NSURL *applicationFilesDirectory = [[NSApp delegate] applicationFilesDirectory];

    // convert old store to an sqlite store
    NSURL *newUrl = [applicationFilesDirectory URLByAppendingPathComponent:@"Hive.storedata.new"];

    if ([fileManager fileExistsAtPath:newUrl.path]) {
        [self deletePersistentStoreAtURL:newUrl error:&error];
        CheckError(error);
    }

    NSPersistentStore *sqliteStore = [coordinator migratePersistentStore:xmlStore
                                                                   toURL:newUrl
                                                                 options:nil
                                                                withType:NSSQLiteStoreType
                                                                   error:&error];
    CheckError(error);

    // back up the old store
    NSURL *backupUrl = [applicationFilesDirectory URLByAppendingPathComponent:@"Hive.storedata.old"];

    if ([fileManager fileExistsAtPath:backupUrl.path]) {
        [fileManager removeItemAtURL:backupUrl error:&error];
        CheckError(error);
    }

    [fileManager moveItemAtURL:url toURL:backupUrl error:&error];
    CheckError(error);

    // move the new store to the old place
    NSPersistentStore *movedSqliteStore = [coordinator migratePersistentStore:sqliteStore
                                                                        toURL:url
                                                                      options:nil
                                                                     withType:NSSQLiteStoreType
                                                                        error:&error];
    CheckError(error);

    [self deletePersistentStoreAtURL:newUrl error:&error];
    CheckError(error);

    return movedSqliteStore;
}

- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext) {
        return _managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;

    if (!coordinator) {
        NSDictionary *dict = @{
                               NSLocalizedDescriptionKey: @"Failed to initialize the store",
                               NSLocalizedFailureReasonErrorKey: @"There was an error building up the data file."
                             };

        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [NSApp presentError:error];
        return nil;
    }

    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _managedObjectContext.persistentStoreCoordinator = coordinator;

    return _managedObjectContext;
}

@end
