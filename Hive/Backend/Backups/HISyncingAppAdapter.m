//
//  HISyncingAppAdapter.m
//  Hive
//
//  Created by Jakub Suder on 22/07/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HIDatabaseManager.h"
#import "HISyncingAppAdapter.h"
#import "NSAlert+Hive.h"


static NSString * const LastBackupKey = @"lastBackup";
static NSString * const LocationKey = @"location";

const NSInteger HISyncingAppAdapterNotConfigured = -1;
const NSInteger HISyncingAppAdapterCouldntComplete = -2;
const NSInteger HISyncingAppAdapterNotRunning = -3;


@implementation HISyncingAppAdapter

- (instancetype)init {
    self = [super init];

    if (self) {
        self.status = HIBackupStatusWaiting;
        self.error = nil;
        self.lastBackupDate = self.lastRegisteredBackup;
    }

    return self;
}


#pragma mark - Superclass method overrides

- (BOOL)requiresEncryption {
    return YES;
}

- (BOOL)canBeConfigured {
    return YES;
}

- (BOOL)needsToBeConfigured {
    NSArray *syncFolders = [self existingSyncFolders];

    return !self.backupLocation && (syncFolders.count != 1);
}

- (BOOL)isVisible {
    return YES;
}

- (void)setEnabled:(BOOL)newState {
    [super setEnabled:newState];

    if (newState == false) {
        // clear location setting if it's invalid
        if (self.backupLocation && ![self pathIsInsideSyncFolder:self.backupLocation]) {
            self.backupLocation = nil;
        }
    }
}

- (void)updateStatus {
    if (self.error.code == HISyncingAppAdapterNotRunning) {
        // we've done the backup but we're waiting for the syncing app to be started
        if ([self isSyncingAppRunning]) {
            [self registerSuccessfulBackup];
        }
    } else if (self.status == HIBackupStatusDisabled) {
        // backup was just switched on
        [self performBackup];
    }
}


#pragma mark - Required configuration

- (NSString *)syncingAppId {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSArray *)syncFolders {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSString *)defaultBackupFolder {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSString *)errorDomain {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSString *)errorTitleForSelectedFolderOutsideSyncFolder {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSString *)errorMessageForSelectedFolderOutsideSyncFolder {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSString *)errorTitleForAppNotInstalled {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSString *)errorMessageForAppNotInstalled {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSString *)errorMessageForAppNotRunning {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSString *)promptMessageForChooseBackupFolder {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}


#pragma mark - Configuring backup

- (NSDate *)lastRegisteredBackup {
    return self.adapterSettings[LastBackupKey];
}

- (void)setLastRegisteredBackup:(NSDate *)date {
    NSMutableDictionary *adapterSettings = self.adapterSettings;
    [adapterSettings setObject:date forKey:LastBackupKey];
    [self saveAdapterSettings:adapterSettings];
}

- (NSString *)backupLocation {
    return self.adapterSettings[LocationKey];
}

- (void)setBackupLocation:(NSString *)location {
    NSMutableDictionary *adapterSettings = self.adapterSettings;

    if (location) {
        [adapterSettings setObject:location forKey:LocationKey];
    } else {
        [adapterSettings removeObjectForKey:LocationKey];
    }

    [self saveAdapterSettings:adapterSettings];
}

- (NSArray *)existingSyncFolders {
    NSArray *folders = [self syncFolders];

    if (!folders) {
        return nil;
    }

    NSMutableArray *existingFolders = [[NSMutableArray alloc] initWithCapacity:folders.count];

    for (NSString *path in folders) {
        BOOL isDirectory = NO;
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];

        if (exists && isDirectory) {
            [existingFolders addObject:path];
        } else {
            HILogWarn(@"Sync folder not found (path=%@, exists=%d, isDirectory=%d)", path, exists, isDirectory);
        }
    }

    return existingFolders;
}

- (NSString *)backupFolderName {
    NSString *prefix = [[[BCClient sharedClient] walletHash] substringToIndex:5];
    return [@"Hive-" stringByAppendingString:prefix];
}

- (NSString *)syncFolderFromDetectionScript:(NSString *)scriptName {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = [[NSBundle mainBundle] pathForResource:scriptName ofType:@"sh"];
    task.standardOutput = [NSPipe pipe];
    task.standardError = [NSPipe pipe];

    [task launch];
    [task waitUntilExit];

    NSData *outputData = [[task.standardOutput fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    output = [output stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (task.terminationStatus == 0) {
        return output;
    } else {
        NSData *errorData = [[task.standardError fileHandleForReading] readDataToEndOfFile];
        NSString *errorText = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];

        HILogWarn(@"%@ failed: output = '%@', error = '%@', return code = %d",
                  scriptName, output, errorText, task.terminationStatus);

        return nil;
    }
}

- (BOOL)pathIsInsideSyncFolder:(NSString *)path {
    NSArray *syncFolders = [self syncFolders];

    if (syncFolders) {
        for (NSString *folder in syncFolders) {
            if ([path hasPrefix:folder]) {
                return YES;
            }
        }
    }

    return NO;
}

- (void)configureInWindow:(NSWindow *)window {
    // show error if there are no sync folders configured
    NSArray *syncFolders = [self syncFolders];

    if (syncFolders.count == 0) {
        NSAlert *alert = [NSAlert hiOKAlertWithTitle:[self errorTitleForAppNotInstalled]
                                             message:[self errorMessageForAppNotInstalled]];

        [alert beginSheetModalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
        return;
    }

    // choose one of the existing folders as a starting point, fall back to home
    NSArray *existingFolders = [self existingSyncFolders];
    NSString *initialFolder = [existingFolders firstObject] ?: NSHomeDirectory();

    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.prompt = NSLocalizedString(@"Choose", @"Backup folder save panel confirmation button");
    panel.message = [self promptMessageForChooseBackupFolder];
    panel.directoryURL = [NSURL fileURLWithPath:initialFolder];
    panel.canChooseDirectories = YES;
    panel.canCreateDirectories = YES;
    panel.canChooseFiles = NO;

    [panel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self backupFolderSelected:panel.URL.path inWindow:window];
            });
        }
    }];
}

- (void)backupFolderSelected:(NSString *)selectedDirectory inWindow:(NSWindow *)window {
    if (![self pathIsInsideSyncFolder:selectedDirectory]) {
        HILogWarn(@"Selected directory outside sync folder (%@, sync folders: %@)",
                  selectedDirectory, [self syncFolders]);

        NSAlert *alert = [NSAlert hiOKAlertWithTitle:[self errorTitleForSelectedFolderOutsideSyncFolder]
                                             message:[self errorMessageForSelectedFolderOutsideSyncFolder]];

        [alert beginSheetModalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
        return;
    }

    self.backupLocation = selectedDirectory;
    self.enabled = YES;
}


#pragma mark - Performing backup

- (void)performBackup {
    if (!self.backupLocation) {
        self.backupLocation = [self defaultBackupFolder];
    }

    NSURL *backupLocation = self.backupLocation ? [NSURL fileURLWithPath:self.backupLocation] : nil;

    if (!backupLocation) {
        HILogWarn(@"Backup not configured (no backup location)");

        self.status = HIBackupStatusFailure;
        self.error = BackupError(self.errorDomain, HISyncingAppAdapterNotConfigured,
                                 NSLocalizedString(@"Backup is not configured", @"Backup error message"));
        return;
    }

    if (![self pathIsInsideSyncFolder:backupLocation.path]) {
        HILogWarn(@"Backup directory outside sync folder (%@, sync folders: %@)",
                  backupLocation, [self syncFolders]);

        self.status = HIBackupStatusFailure;
        self.error = BackupError(self.errorDomain, HISyncingAppAdapterNotConfigured,
                                 [self errorTitleForSelectedFolderOutsideSyncFolder]);

        return;
    }

    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:backupLocation.path isDirectory:&isDirectory];

    if (!exists) {
        NSError *error = nil;

        [[NSFileManager defaultManager] createDirectoryAtPath:backupLocation.path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];

        if (error) {
            HILogWarn(@"Backup not configured properly (backup folder can't be created at %@: %@)",
                      backupLocation, error);

            self.status = HIBackupStatusFailure;
            self.error = BackupError(self.errorDomain, HISyncingAppAdapterNotConfigured,
                                     NSLocalizedString(@"Can't create a directory to store the wallet backup",
                                                       @"Backup error message"));
            return;
        }
    } else if (!isDirectory) {
        HILogWarn(@"Backup not configured properly (backup folder can't be created at %@, something exists there)",
                  backupLocation);

        self.status = HIBackupStatusFailure;
        self.error = BackupError(self.errorDomain, HISyncingAppAdapterNotConfigured,
                                 NSLocalizedString(@"Can't create a directory to store the wallet backup",
                                                   @"Backup error message"));
        return;
    }

    if (![self backUpCoreDataStore]) {
        return;
    }

    if (![self backUpWallet]) {
        return;
    }

    if ([self isSyncingAppRunning]) {
        [self registerSuccessfulBackup];
    } else {
        HILogWarn(@"Backup not finished - syncing app isn't running");

        // we'll keep checking in updateStatus
        self.status = [self updatedAfterLastWalletChange] ? HIBackupStatusOutdated : HIBackupStatusFailure;
        self.error = BackupError(self.errorDomain, HISyncingAppAdapterNotRunning, [self errorMessageForAppNotRunning]);
    }
}

- (BOOL)backUpCoreDataStore {
    NSURL *backupLocation = [NSURL fileURLWithPath:self.backupLocation];
    NSError *error = nil;

    [[HIDatabaseManager sharedManager] backupStoreToDirectory:backupLocation error:&error];

    if (error) {
        self.status = HIBackupStatusFailure;
        self.error = BackupError(self.errorDomain, HISyncingAppAdapterCouldntComplete, error.localizedFailureReason);
        return NO;
    }

    return YES;
}

- (BOOL)backUpWallet {
    NSURL *backupLocation = [NSURL fileURLWithPath:self.backupLocation];
    NSURL *bitcoinjDirectory = [backupLocation URLByAppendingPathComponent:BCClientBitcoinjDirectory];

    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:bitcoinjDirectory.path isDirectory:&isDirectory];

    NSError *error = nil;

    if (!exists) {
        [[NSFileManager defaultManager] createDirectoryAtURL:bitcoinjDirectory
                                 withIntermediateDirectories:NO
                                                  attributes:nil
                                                       error:&error];

        if (error) {
            HILogError(@"Couldn't create backup directory: %@", error);

            self.status = HIBackupStatusFailure;
            self.error = BackupError(self.errorDomain, HISyncingAppAdapterCouldntComplete,
                                     error.localizedFailureReason);
            return NO;
        }
    } else if (!isDirectory) {
        self.status = HIBackupStatusFailure;
        self.error = BackupError(self.errorDomain, HISyncingAppAdapterCouldntComplete,
                                 NSLocalizedString(@"Can't create a directory to store the wallet backup",
                                                   @"Backup error message"));

        HILogError(@"Couldn't create backup directory: %@ is a file", bitcoinjDirectory);
        [NSApp presentError:self.error];

        return NO;
    }

    [[BCClient sharedClient] backupWalletToDirectory:bitcoinjDirectory error:&error];

    if (error) {
        self.status = HIBackupStatusFailure;
        self.error = BackupError(self.errorDomain, HISyncingAppAdapterCouldntComplete, error.localizedFailureReason);
        return NO;
    }
    
    return YES;
}

- (void)registerSuccessfulBackup {
    self.status = HIBackupStatusUpToDate;
    self.error = nil;
    self.lastBackupDate = [NSDate date];
    self.lastRegisteredBackup = self.lastBackupDate;
}

- (BOOL)isSyncingAppRunning {
    return ([NSRunningApplication runningApplicationsWithBundleIdentifier:[self syncingAppId]].count > 0);
}

@end
