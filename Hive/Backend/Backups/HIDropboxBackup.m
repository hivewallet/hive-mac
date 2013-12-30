//
//  HIDropboxBackup.m
//  Hive
//
//  Created by Jakub Suder on 23.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIDropboxBackup.h"

@implementation HIDropboxBackup

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

- (HIBackupAdapterStatus)status {
    if (!self.enabled) {
        return HIBackupStatusDisabled;
    } else {
        return HIBackupStatusUpToDate;
    }
}

- (NSError *)error {
    return nil;
}

- (NSDate *)lastBackupDate {
    return nil;
}

- (void)updateStatus {
    // TODO
    [self willChangeValueForKey:@"status"];
    [self didChangeValueForKey:@"status"];
}

- (BOOL)isEnabledByDefault {
    return NO;
}

@end
