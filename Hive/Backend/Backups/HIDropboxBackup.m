//
//  HIDropboxBackup.m
//  Hive
//
//  Created by Jakub Suder on 23.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HIDatabaseManager.h"
#import "HIDropboxBackup.h"

static NSString * const LocationKey = @"location";
static NSString * const LastBackupKey = @"lastBackup";

NSString * const HIDropboxBackupError = @"HIDropboxBackupError";
const NSInteger HIDropboxBackupNotConfigured = -1;
const NSInteger HIDropboxBackupCouldntComplete = -2;
const NSInteger HIDropboxBackupNotRunning = -3;


@interface HIDropboxBackup ()

@property (nonatomic, copy) NSString *backupLocation;
@property (nonatomic, copy) NSDate *lastRegisteredBackup;

@end


@implementation HIDropboxBackup

- (id)init {
    self = [super init];

    if (self) {
        self.status = HIBackupStatusWaiting;
        self.error = nil;
        self.lastBackupDate = self.lastRegisteredBackup;
    }

    return self;
}


#pragma mark - Superclass method overrides

- (NSString *)name {
    return @"dropbox";
}

- (NSString *)displayedName {
    return @"Dropbox";
}

- (NSImage *)icon {
    return [NSImage imageNamed:@"dropbox-glyph-blue"];
}

- (CGFloat)iconSize {
    return 44.0;
}

- (BOOL)isEnabledByDefault {
    return NO;
}

- (BOOL)requiresEncryption {
    return YES;
}

- (BOOL)needsToBeConfigured {
    return YES;
}

- (void)updateStatus {
    if (!self.enabled) {
        self.status = HIBackupStatusDisabled;
        self.error = nil;
    } else if (self.error.code == HIDropboxBackupNotRunning) {
        // we've done the backup but we're waiting for Dropbox to be started
        if ([self isDropboxRunning]) {
            [self registerSuccessfulBackup];
        }
    } else if (self.status == HIBackupStatusDisabled) {
        // backup was just switched on
        [self performBackup];
    }
}


#pragma mark - Configuring backup

- (NSString *)dropboxFolder {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = [[NSBundle mainBundle] pathForResource:@"get_dropbox_folder" ofType:@"sh"];
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

        HILogError(@"get_dropbox_folder failed: output = '%@', error = '%@', return code = %d",
                   output, errorText, task.terminationStatus);

        return nil;
    }
}

- (NSString *)backupLocation {
    return self.adapterSettings[LocationKey];
}

- (void)setBackupLocation:(NSString *)location {
    NSMutableDictionary *adapterSettings = self.adapterSettings;
    [adapterSettings setObject:location forKey:LocationKey];
    [self saveAdapterSettings:adapterSettings];
}

- (NSDate *)lastRegisteredBackup {
    return self.adapterSettings[LastBackupKey];
}

- (void)setLastRegisteredBackup:(NSDate *)date {
    NSMutableDictionary *adapterSettings = self.adapterSettings;
    [adapterSettings setObject:date forKey:LastBackupKey];
    [self saveAdapterSettings:adapterSettings];
}

- (void)configureInWindow:(NSWindow *)window {
    BOOL isDirectory;
    BOOL exists = NO;

    NSString *dropboxFolder = [self dropboxFolder];

    if (dropboxFolder) {
        exists = [[NSFileManager defaultManager] fileExistsAtPath:dropboxFolder isDirectory:&isDirectory];
    }

    if (!exists || !isDirectory) {
        HILogWarn(@"Dropbox folder not found (path=%@, exists=%d, isDirectory=%d)", dropboxFolder, exists, isDirectory);

        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Dropbox folder not found",
                                                                         @"Dropbox no backup folder alert title")
                                         defaultButton:NSLocalizedString(@"OK", @"OK button title")
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"You must install Dropbox first "
                                                                         @"(see www.dropbox.com).",
                                                                         @"Dropbox no backup folder alert details")];
        [alert beginSheetModalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
        return;
    }

    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.prompt = NSLocalizedString(@"Choose", @"Dropbox folder save panel confirmation button");
    panel.message = NSLocalizedString(@"Choose a directory inside Dropbox folder where the backup should be saved:",
                                      nil);
    panel.directoryURL = [NSURL fileURLWithPath:dropboxFolder];
    panel.canChooseDirectories = YES;
    panel.canCreateDirectories = YES;
    panel.canChooseFiles = NO;

    [panel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [self backupFolderSelected:panel.URL.path inWindow:window];
        }
    }];
}

- (void)backupFolderSelected:(NSString *)selectedDirectory inWindow:(NSWindow *)window {
    NSString *dropboxFolder = [self dropboxFolder];

    if (dropboxFolder && ![selectedDirectory hasPrefix:dropboxFolder]) {
        HILogWarn(@"Selected directory outside Dropbox folder (%@ vs. %@)", selectedDirectory, dropboxFolder);

        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Selected directory is outside Dropbox folder",
                                                                         @"Dropbox invalid folder alert title")
                                         defaultButton:NSLocalizedString(@"OK", @"OK button title")
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"You need to choose or create a directory "
                                                                         @"inside your Dropbox folder.",
                                                                         @"Dropbox invalid folder alert details")];

        [alert beginSheetModalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
        return;
    }

    self.backupLocation = selectedDirectory;
    self.enabled = YES;
}


#pragma mark - Performing backup

- (void)performBackup {
    if (!self.enabled) {
        self.status = HIBackupStatusDisabled;
        self.error = nil;
        return;
    }

    NSURL *backupLocation = [NSURL fileURLWithPath:self.backupLocation];

    if (!backupLocation) {
        HILogWarn(@"Backup not configured (no backup location)");

        self.status = HIBackupStatusFailure;
        self.error = BackupError(HIDropboxBackupError, HIDropboxBackupNotConfigured, @"Backup is not configured");
        return;
    }

    NSString *dropboxFolder = [self dropboxFolder];

    if (!dropboxFolder) {
        HILogWarn(@"Backup not configured (no Dropbox folder)");

        self.status = HIBackupStatusFailure;
        self.error = BackupError(HIDropboxBackupError, HIDropboxBackupNotConfigured, @"Dropbox folder not found");
        return;
    }

    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:backupLocation.path isDirectory:&isDirectory];

    if (!exists || !isDirectory) {
        HILogWarn(@"Backup not configured (backup folder missing; path=%@, exists=%d, isDirectory=%d)",
                  backupLocation, exists, isDirectory);

        self.status = HIBackupStatusFailure;
        self.error = BackupError(HIDropboxBackupError, HIDropboxBackupNotConfigured, @"Backup folder was deleted");
        return;
    }

    if (![self backUpCoreDataStore]) {
        return;
    }

    if (![self backUpWallet]) {
        return;
    }

    if ([self isDropboxRunning]) {
        [self registerSuccessfulBackup];
    } else {
        HILogWarn(@"Backup not finished - Dropbox isn't running");

        // we'll keep checking in updateStatus
        self.status = [self updatedAfterLastWalletChange] ? HIBackupStatusOutdated : HIBackupStatusFailure;
        self.error = BackupError(HIDropboxBackupError, HIDropboxBackupNotRunning, @"Dropbox isn't running");
    }
}

- (BOOL)backUpCoreDataStore {
    NSURL *backupLocation = [NSURL fileURLWithPath:self.backupLocation];
    NSError *error = nil;

    [[HIDatabaseManager sharedManager] backupStoreToDirectory:backupLocation error:&error];

    if (error) {
        [NSApp presentError:error];
        self.status = HIBackupStatusFailure;
        self.error = BackupError(HIDropboxBackupError, HIDropboxBackupCouldntComplete, error.localizedFailureReason);
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
            [NSApp presentError:error];

            self.status = HIBackupStatusFailure;
            self.error = BackupError(HIDropboxBackupError, HIDropboxBackupCouldntComplete, error.localizedFailureReason);
            return NO;
        }
    } else if (!isDirectory) {
        self.status = HIBackupStatusFailure;
        self.error = BackupError(HIDropboxBackupError, HIDropboxBackupCouldntComplete,
                                 @"Can't create a directory to store the wallet backup");

        HILogError(@"Couldn't create backup directory: %@ is a file", bitcoinjDirectory);
        [NSApp presentError:self.error];

        return NO;
    }

    [[BCClient sharedClient] backupWalletToDirectory:bitcoinjDirectory error:&error];

    if (error) {
        [NSApp presentError:error];
        self.status = HIBackupStatusFailure;
        self.error = BackupError(HIDropboxBackupError, HIDropboxBackupCouldntComplete, error.localizedFailureReason);
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

- (BOOL)isDropboxRunning {
    return ([NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.getdropbox.dropbox"].count > 0);
}

@end
