//
//  HITimeMachineBackup.m
//  Hive
//
//  Created by Jakub Suder on 23.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HITimeMachineBackup.h"

static const NSTimeInterval RecentBackupLimit = 86400 * 30; // 30 days


@interface HITimeMachineBackup ()

@property (nonatomic) HIBackupAdapterStatus status;

@end


@implementation HITimeMachineBackup

// override abstract superclass implementation
@synthesize status;

- (NSString *)name {
    return @"time_machine";
}

- (NSString *)displayedName {
    return @"Time Machine";
}

- (NSImage *)icon {
    return [[NSImage alloc] initWithContentsOfFile:@"/Applications/Time Machine.app/Contents/Resources/backup.icns"];
}

- (void)updateStatus {
    HIBackupAdapterStatus currentStatus = [self currentStatus];

    if (currentStatus != self.status) {
        self.status = currentStatus;
    }
}

- (HIBackupAdapterStatus)currentStatus {
    if (!self.enabled) {
        return HIBackupStatusDisabled;
    }

    NSDictionary *settings = [self timeMachineSettings];
    BOOL backupsEnabled = [settings[@"AutoBackup"] boolValue];
    NSDate *lastBackup = [settings[@"Destinations"][0][@"SnapshotDates"] lastObject];

    // TODO: record last change date in the wallet file
    NSDate *lastWalletChange = [NSDate distantPast];

    if (!lastBackup || [self isExcludedFromBackup]) {
        // backups aren't happening at all or Hive isn't included in them
        return HIBackupStatusFailure;
    }

    BOOL updatedRecently = ([[NSDate date] timeIntervalSinceDate:lastBackup] < RecentBackupLimit);
    BOOL afterLastWalletChange = [lastBackup isGreaterThan:lastWalletChange];

    if (backupsEnabled && updatedRecently) {
        if (afterLastWalletChange) {
            // everything's fresh
            return HIBackupStatusUpToDate;
        } else {
            // we don't have a backup, but we should have one soon
            return HIBackupStatusWaiting;
        }
    } else {
        if (afterLastWalletChange) {
            // we have a backup, but we probably won't have another
            return HIBackupStatusOutdated;
        } else {
            // we don't have a backup and we probably won't have another
            return HIBackupStatusFailure;
        }
    }
}

- (BOOL)isEnabledByDefault {
    return YES;
}

- (NSDictionary *)timeMachineSettings {
    NSURL *library = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory
                                                             inDomains:NSLocalDomainMask] firstObject];
    NSURL *preferences = [library URLByAppendingPathComponent:@"Preferences"];
    NSURL *settingsFile = [preferences URLByAppendingPathComponent:@"com.apple.TimeMachine.plist"];
    NSData *settingsData = [NSData dataWithContentsOfURL:settingsFile];

    return [NSPropertyListSerialization propertyListWithData:settingsData options:0 format:NULL error:NULL];
}

- (BOOL)isExcludedFromBackup {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/tmutil";
    task.arguments = @[@"isexcluded", [[[NSApp delegate] applicationFilesDirectory] path]];
    task.standardOutput = [NSPipe pipe];

    [task launch];

    NSData *outputData = [[task.standardOutput fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

    return ([output rangeOfString:@"[Included]"].location == NSNotFound);
}

@end
