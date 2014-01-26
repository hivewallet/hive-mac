//
//  HIDatabaseManager.m
//  Hive
//
//  Created by Jakub Suder on 10.12.13.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HIDatabaseManager.h"

#define CheckError(error)               \
    if (error) {                        \
        HILogError(@"%@", error);       \
        [self presentError:(error)];    \
        return nil;                     \
    }

static NSString * const StoreFileName = @"Hive.storedata";
static NSString * const HIDatabaseManagerErrorDomain = @"HIDatabaseManagerErrorDomain";
static NSInteger HIDatabaseManagerFileExistsAtLocationError = 1000;

@interface HIDatabaseManager ()

@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation HIDatabaseManager

+ (HIDatabaseManager *)sharedManager {
    static HIDatabaseManager *_sharedManager = nil;
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        _sharedManager = [[self alloc] init];
    });

    return _sharedManager;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (!_managedObjectModel) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Hive" withExtension:@"momd"];
        self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }

    return _managedObjectModel;
}

- (NSURL *)persistentStoreURL {
    return [[[NSApp delegate] applicationFilesDirectory] URLByAppendingPathComponent:StoreFileName];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }

    NSManagedObjectModel *mom = self.managedObjectModel;

    if (!mom) {
        HILogError(@"No model to generate a store from");
        return nil;
    }

    NSURL *applicationFilesDirectory = [[NSApp delegate] applicationFilesDirectory];
    HILogDebug(@"Using application support directory: %@", applicationFilesDirectory);
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

        error = [NSError errorWithDomain:HIDatabaseManagerErrorDomain
                                    code:HIDatabaseManagerFileExistsAtLocationError
                                userInfo:@{NSLocalizedDescriptionKey: failureDescription}];

        CheckError(error);
    }

    NSURL *url = [self persistentStoreURL];
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

        NSError *xmlError = nil;

        // see if it isn't the old xml version
        NSPersistentStore *xmlStore = [coordinator addPersistentStoreWithType:NSXMLStoreType
                                                                configuration:nil
                                                                          URL:url
                                                                      options:storeOptions
                                                                        error:&xmlError];

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

    NSDictionary *storeOptions = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                                   NSInferMappingModelAutomaticallyOption: @YES};

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSURL *url = xmlStore.URL;
    NSURL *applicationFilesDirectory = [[NSApp delegate] applicationFilesDirectory];

    // convert old store to an sqlite store
    NSString *newFileName = [StoreFileName stringByAppendingString:@".new"];
    NSURL *newUrl = [applicationFilesDirectory URLByAppendingPathComponent:newFileName];

    if ([fileManager fileExistsAtPath:newUrl.path]) {
        [self deletePersistentStoreAtURL:newUrl error:&error];
        CheckError(error);
    }

    NSPersistentStore *sqliteStore = [coordinator migratePersistentStore:xmlStore
                                                                   toURL:newUrl
                                                                 options:storeOptions
                                                                withType:NSSQLiteStoreType
                                                                   error:&error];
    CheckError(error);

    // back up the old store
    NSString *oldFileName = [StoreFileName stringByAppendingString:@".old"];
    NSURL *backupUrl = [applicationFilesDirectory URLByAppendingPathComponent:oldFileName];

    if ([fileManager fileExistsAtPath:backupUrl.path]) {
        [fileManager removeItemAtURL:backupUrl error:&error];
        CheckError(error);
    }

    [fileManager moveItemAtURL:url toURL:backupUrl error:&error];
    CheckError(error);

    // move the new store to the old place
    NSPersistentStore *movedSqliteStore = [coordinator migratePersistentStore:sqliteStore
                                                                        toURL:url
                                                                      options:storeOptions
                                                                     withType:NSSQLiteStoreType
                                                                        error:&error];
    CheckError(error);

    [self deletePersistentStoreAtURL:newUrl error:&error];
    CheckError(error);

    return movedSqliteStore;
}

- (void)backupStoreToDirectory:(NSURL *)backupLocation error:(NSError **)error {
    HILogInfo(@"Backing up Core Data store to %@", backupLocation);
    NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"This method must be run on the main thread");

    NSError *backupError = nil;

    NSURL *standardLocation = [self persistentStoreURL];
    NSURL *backupFileLocation = [backupLocation URLByAppendingPathComponent:StoreFileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:backupFileLocation.path]) {
        // apparently migrating onto an existing file will concatenate new store with the old one...
        [fileManager removeItemAtURL:backupFileLocation error:&backupError];

        if (backupError) {
            HILogError(@"Error during store backup: %@", backupError);
            *error = backupError;
            return;
        }
    }

    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;

    // prevent creating additional journal files (sha/wal)
    NSDictionary *storeOptions = @{
                                   NSMigratePersistentStoresAutomaticallyOption: @YES,
                                   NSInferMappingModelAutomaticallyOption: @YES,
                                   NSSQLitePragmasOption: @{ @"journal_mode": @"DELETE" }
                                 };

    NSPersistentStore *backupStore = [coordinator migratePersistentStore:coordinator.persistentStores.firstObject
                                                                   toURL:backupFileLocation
                                                                 options:storeOptions
                                                                withType:NSSQLiteStoreType
                                                                   error:&backupError];

    if (backupError) {
        HILogError(@"Error during store backup: %@", backupError);
        *error = backupError;
        return;
    }

    [coordinator removePersistentStore:backupStore
                                 error:&backupError];

    if (backupError) {
        HILogError(@"Error during store backup: %@", backupError);
        *error = backupError;
        return;
    }

    [coordinator addPersistentStoreWithType:NSSQLiteStoreType
                              configuration:nil
                                        URL:standardLocation
                                    options:nil
                                      error:&backupError];

    if (backupError) {
        HILogError(@"Error during store backup: %@", backupError);
        *error = backupError;
        return;
    }
}

- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext) {
        return _managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;

    if (!coordinator) {
        HILogError(@"No persistent store coordinator, can't create managed object context.");
        return nil;
    }

    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _managedObjectContext.persistentStoreCoordinator = coordinator;

    return _managedObjectContext;
}

- (void)presentError:(NSError *)error {
    NSString *explanation = error.localizedDescription;

    if ([error.domain isEqual:NSCocoaErrorDomain]) {
        switch (error.code) {
            case NSMigrationMissingSourceModelError:
                explanation = NSLocalizedString(@"The database was saved by a newer version of Hive - "
                                                @"please download the latest version from http://hivewallet.com.",
                                                @"Error message when database is incompatible with this version");
        }
    }

    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Hive database file cannot be opened.",
                                                                     @"Database error alert title")
                                     defaultButton:NSLocalizedString(@"OK", @"OK button title")
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"%@", explanation];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert runModal];
}

@end
