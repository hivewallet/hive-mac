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


@implementation HIBackupAdapter

+ (void)initialize {
    if (DEBUG_OPTION_ENABLED(TESTING_NETWORK)) {
        BackupSettingsKey = @"BackupAdaptersTest";
    } else {
        BackupSettingsKey = @"BackupAdapters";
    }
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

/* Tells if the adapter needs to be configured (e.g. by setting the backup path) before it can be enabled */
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
    // not required if needsToBeConfigured == NO
}

- (void)performBackup {
    // do the actual backup now, unless it happens automatically
}


#pragma mark - Helpers and other properties

+ (NSDictionary *)backupSettings {
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:BackupSettingsKey];
}

/* Last known backup status */
- (void)setStatus:(HIBackupAdapterStatus)status {
    if (status != _status) {
        [self willChangeValueForKey:@"status"];
        _status = status;
        [self didChangeValueForKey:@"status"];
    }
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

/* Date of the last backup, if there was any */
- (void)setLastBackupDate:(NSDate *)lastBackupDate {
    if (lastBackupDate != _lastBackupDate) {
        [self willChangeValueForKey:@"lastBackupDate"];
        _lastBackupDate = lastBackupDate;
        [self didChangeValueForKey:@"lastBackupDate"];
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

    [self updateStatus];
}

- (NSDate *)lastWalletChange {
    return [[BCClient sharedClient] lastWalletChangeDate] ?: [NSDate distantPast];
}

- (BOOL)updatedAfterLastWalletChange {
    return [self.lastBackupDate isGreaterThan:[self lastWalletChange]];
}

@end
