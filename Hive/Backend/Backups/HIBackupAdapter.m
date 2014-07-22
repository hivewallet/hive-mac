//
//  HIBackupAdapter.m
//  Hive
//
//  Created by Jakub Suder on 23.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HIBackupAdapter.h"

static NSString *BackupSettingsKey;
static NSString * const EnabledKey = @"enabled";
static NSDateFormatter *lastBackupDateFormatter;

NSString *HIBackupStatusTextDisabled;
NSString *HIBackupStatusTextUpToDate;
NSString *HIBackupStatusTextWaiting;
NSString *HIBackupStatusTextOutdated;
NSString *HIBackupStatusTextFailure;


@implementation HIBackupAdapter

+ (void)initialize {
    if (DEBUG_OPTION_ENABLED(TESTING_NETWORK)) {
        BackupSettingsKey = @"BackupAdaptersTest";
    } else {
        BackupSettingsKey = @"BackupAdapters";
    }

    lastBackupDateFormatter = [[NSDateFormatter alloc] init];
    lastBackupDateFormatter.dateStyle = NSDateFormatterLongStyle;
    lastBackupDateFormatter.timeStyle = NSDateFormatterNoStyle;

    HIBackupStatusTextDisabled = NSLocalizedString(@"Disabled",
                                                   @"Backup status: adapter disabled");

    HIBackupStatusTextUpToDate = NSLocalizedString(@"Up to date",
                                                   @"Backup status: backup up to date");

    HIBackupStatusTextOutdated = NSLocalizedString(@"Backup problem",
                                                   @"Backup status: backup done but not updated recently");

    HIBackupStatusTextWaiting = NSLocalizedString(@"Waiting for backup",
                                                  @"Backup status: backup scheduled or in progress");

    HIBackupStatusTextFailure = NSLocalizedString(@"Backup error",
                                                  @"Backup status: backup can't or won't be completed");
}


#pragma mark - Abstract methods

/* Internal name of the adapter, e.g. @"time_machine" */
- (NSString *)name {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

/* Displayed name of the adapter, e.g. @"Time Machine" */
- (NSString *)displayedName {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

/* Image/icon displayed next to the adapter name */
- (NSImage *)icon {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

/* Tells if the adapter should be enabled by default on first launch */
- (BOOL)isEnabledByDefault {
    [self doesNotRecognizeSelector:_cmd];
    return NO;
}

/* Tells if the adapter can be configured (e.g. by setting the backup path) before it can be enabled */
- (BOOL)canBeConfigured {
    [self doesNotRecognizeSelector:_cmd];
    return NO;
}

/* Tells if the adapter *needs* to be configured before it can be enabled */
- (BOOL)needsToBeConfigured {
    [self doesNotRecognizeSelector:_cmd];
    return NO;
}

/* Tells if the wallet needs to be encrypted before you turn this on (this is temporary because soon encryption
   will be required anyway). */
- (BOOL)requiresEncryption {
    [self doesNotRecognizeSelector:_cmd];
    return NO;
}

/* Tells if the wallet is shown in backup configuration UIs (wizard / backup center). */
- (BOOL)isVisible {
    [self doesNotRecognizeSelector:_cmd];
    return NO;
}

/* Check if backup status has changed, and update self.status, self.error and self.lastBackupDate if needed */
- (void)updateStatus {
    [self doesNotRecognizeSelector:_cmd];
}


#pragma mark - Overridable methods

/* Override if you need a different icon size */
- (CGFloat)iconSize {
  return 36.0;
}

- (void)configureInWindow:(NSWindow *)window {
    // not required if canBeConfigured == NO
}

- (void)performBackup {
    // do the actual backup now, unless it happens automatically
}


#pragma mark - Helpers and other properties

+ (NSDictionary *)backupSettings {
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:BackupSettingsKey];
}

+ (void)resetBackupSettings {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:BackupSettingsKey];
}

/* Details of the problem with the backup, if there is any  */
- (void)setError:(NSError *)error {
    if (error != _error) {
        [self willChangeValueForKey:@"error"];
        _error = error;
        [self didChangeValueForKey:@"error"];

        NSString *newMessage = error.localizedFailureReason;

        if ((_errorMessage || newMessage) && ![_errorMessage isEqual:newMessage]) {
            [self willChangeValueForKey:@"errorMessage"];
            _errorMessage = newMessage;
            [self didChangeValueForKey:@"errorMessage"];
        }
    }
}

- (NSString *)lastBackupInfo {
    if (!self.lastBackupDate) {
        return NSLocalizedString(@"Backup hasn't been done yet", nil);
    } else if (self.status == HIBackupStatusFailure || self.status == HIBackupStatusOutdated) {
        return [NSString stringWithFormat:NSLocalizedString(@"No backup since %@",
                                                            @"Backup is outdated, last backup was on that date"),
                [lastBackupDateFormatter stringFromDate:self.lastBackupDate]];
    } else {
        return [NSString stringWithFormat:NSLocalizedString(@"Last backup on %@",
                                                            @"On what date was the last backup done"),
                [lastBackupDateFormatter stringFromDate:self.lastBackupDate]];
    }
}

- (NSMutableDictionary *)adapterSettings {
    NSDictionary *backupsDictionary = [[self class] backupSettings];

    return [backupsDictionary[self.name] mutableCopy] ?: [NSMutableDictionary new];
}

- (void)saveAdapterSettings:(NSDictionary *)settings {
    NSMutableDictionary *backupsDictionary = [[[self class] backupSettings] mutableCopy] ?: [NSMutableDictionary new];

    backupsDictionary[self.name] = settings;

    [[NSUserDefaults standardUserDefaults] setObject:backupsDictionary forKey:BackupSettingsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isEnabled {
    return [self.adapterSettings[EnabledKey] boolValue];
}

- (void)setEnabled:(BOOL)enabled {
    [self willChangeValueForKey:@"status"];
    [self willChangeValueForKey:@"enabled"];

    NSMutableDictionary *adapterSettings = self.adapterSettings;
    [adapterSettings setObject:@(enabled) forKey:EnabledKey];
    [self saveAdapterSettings:adapterSettings];

    [self didChangeValueForKey:@"status"];
    [self didChangeValueForKey:@"enabled"];

    [self updateStatusIfEnabled];
}

- (NSDate *)lastWalletChange {
    return [[BCClient sharedClient] lastWalletChangeDate] ?: [NSDate distantPast];
}

- (BOOL)updatedAfterLastWalletChange {
    return [self.lastBackupDate isGreaterThan:[self lastWalletChange]];
}

- (void)performBackupIfEnabled {
    if (self.enabled) {
        [self performBackup];
    } else {
        [self markAsDisabled];
    }
}

- (void)updateStatusIfEnabled {
    if (self.enabled) {
        [self updateStatus];
    } else {
        [self markAsDisabled];
    }
}

- (void)markAsDisabled {
    self.status = HIBackupStatusDisabled;
    self.error = nil;
    self.lastBackupDate = nil;
}

@end
