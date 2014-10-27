//
//  HIDatabaseManager.m
//  Hive
//
//  Created by Jakub Suder on 10.12.13.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HIDatabaseManager.h"
#import "NSAlert+Hive.h"

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

@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

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
    return [[AppDelegate applicationFilesDirectory] URLByAppendingPathComponent:StoreFileName];
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

    NSURL *applicationFilesDirectory = [AppDelegate applicationFilesDirectory];
    HILogDebug(@"Using application support directory: %@", applicationFilesDirectory);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    BOOL isDirectory;
    BOOL exists = [fileManager fileExistsAtPath:applicationFilesDirectory.path isDirectory:&isDirectory];

    if (!exists) {
        HILogDebug(@"Creating new application support directory");

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

        CheckError(error);
    }

    _persistentStoreCoordinator = coordinator;
    return _persistentStoreCoordinator;
}

- (BOOL)deletePersistentStoreAtURL:(NSURL *)URL error:(NSError **)error {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    for (NSString *suffix in @[@"", @"-journal", @"-wal", @"-shm"]) {
        NSString *path = [URL.path stringByAppendingString:suffix];

        if ([fileManager fileExistsAtPath:path]) {
            [fileManager removeItemAtPath:path error:error];

            if (error && *error) {
                HILogError(@"Can't delete persistent store at %@: %@", path, *error);
                return NO;
            }
        }
    }

    return YES;
}

- (BOOL)backupStoreToDirectory:(NSURL *)backupLocation error:(NSError **)error {
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
            return NO;
        }
    }

    NSPersistentStoreCoordinator *coordinator =
        [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];

    NSPersistentStore *sourceStore = [coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                               configuration:nil
                                                                         URL:standardLocation
                                                                     options:nil
                                                                       error:&backupError];

    if (backupError) {
        HILogError(@"Error during store backup: %@", backupError);
        *error = backupError;
        return NO;
    }

    // prevent creating additional journal files (sha/wal)
    NSDictionary *storeOptions = @{ NSSQLitePragmasOption: @{ @"journal_mode": @"DELETE" }};

    [coordinator migratePersistentStore:sourceStore
                                  toURL:backupFileLocation
                                options:storeOptions
                               withType:NSSQLiteStoreType
                                  error:&backupError];

    if (backupError) {
        HILogError(@"Error during store backup: %@", backupError);
        *error = backupError;
        return NO;
    }

    return YES;
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

    NSAlert *alert = [NSAlert hiOKAlertWithTitle:NSLocalizedString(@"Hive database file cannot be opened.",
                                                                   @"Database error alert title")
                                         message:explanation];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert runModal];
}

@end
