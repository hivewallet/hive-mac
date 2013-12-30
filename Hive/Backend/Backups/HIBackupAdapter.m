//
//  HIBackupAdapter.m
//  Hive
//
//  Created by Jakub Suder on 23.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIBackupAdapter.h"

NSString * const BackupSettingsKey = @"BackupAdapters";
static NSString * const EnabledKey = @"enabled";

@implementation HIBackupAdapter

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

/* Last known backup status */
- (HIBackupAdapterStatus)status {
    [self doesNotRecognizeSelector:_cmd];
    return 0;
}

/* Details of the problem with the backup, if there is any  */
- (NSError *)error {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

/* Date of the last backup, if there was any */
- (NSDate *)lastBackupDate {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

/* Check if backup status has changed, and update self.status if necessary */
- (void)updateStatus {
    [self doesNotRecognizeSelector:_cmd];
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


#pragma mark - Other properties

/* Override if you need a different icon size */
- (CGFloat)iconSize {
  return 36.0;
}

+ (NSDictionary *)backupSettings {
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:BackupSettingsKey];
}

- (BOOL)isEnabled {
    NSDictionary *backupsDictionary = [[self class] backupSettings];
    return [backupsDictionary[self.name][EnabledKey] boolValue];
}

- (void)setEnabled:(BOOL)enabled {
    [self willChangeValueForKey:@"status"];
    [self willChangeValueForKey:@"enabled"];

    NSDictionary *backupsDictionary = [[self class] backupSettings];

    if (backupsDictionary) {
        backupsDictionary = [backupsDictionary mutableCopy];
    } else {
        backupsDictionary = [NSMutableDictionary new];
    }

    NSDictionary *adapterData = backupsDictionary[self.name];

    if (adapterData) {
        adapterData = [adapterData mutableCopy];
    } else {
        adapterData = [NSMutableDictionary new];
    }

    [(NSMutableDictionary *)adapterData setObject:@(enabled) forKey:EnabledKey];
    [(NSMutableDictionary *)backupsDictionary setObject:adapterData forKey:self.name];

    [[NSUserDefaults standardUserDefaults] setObject:backupsDictionary forKey:BackupSettingsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self didChangeValueForKey:@"status"];
    [self didChangeValueForKey:@"enabled"];

    [self updateStatus];
}

- (void)configureInWindow:(NSWindow *)window {
    // not required if needsToBeConfigured == NO
}

@end
