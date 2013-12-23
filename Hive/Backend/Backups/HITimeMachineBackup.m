//
//  HITimeMachineBackup.m
//  Hive
//
//  Created by Jakub Suder on 23.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HITimeMachineBackup.h"

@implementation HITimeMachineBackup

- (NSString *)name {
    return @"time_machine";
}

- (NSString *)displayedName {
    return @"Time Machine";
}

- (NSImage *)icon {
    return [[NSImage alloc] initWithContentsOfFile:@"/Applications/Time Machine.app/Contents/Resources/backup.icns"];
}

- (HIBackupAdapterStatus)status {
    if (!self.enabled) {
        return HIBackupStatusDisabled;
    } else {
        return HIBackupStatusUpToDate;
    }
}

- (BOOL)isEnabledByDefault {
    return YES;
}

@end
