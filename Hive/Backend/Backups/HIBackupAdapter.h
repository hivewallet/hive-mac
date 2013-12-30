//
//  HIBackupAdapter.h
//  Hive
//
//  Created by Jakub Suder on 23.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const BackupSettingsKey;

typedef NS_ENUM(NSUInteger, HIBackupAdapterStatus) {
    // adapter is disabled - user doesn't want to use it
    HIBackupStatusDisabled,

    // backup was done and will (probably) be done again
    HIBackupStatusUpToDate,

    // backup was not done yet but will (probably) be done soon
    HIBackupStatusWaiting,

    // backup was done before (so the keys are safe), but probably won't be done again
    HIBackupStatusOutdated,

    // backup wasn't done and we know or suspect that it will never be
    HIBackupStatusFailure,
};

@interface HIBackupAdapter : NSObject

@property (readonly) NSString *name;
@property (readonly) NSString *displayedName;
@property (readonly) NSImage *icon;
@property (readonly) CGFloat iconSize;
@property (nonatomic, readonly) HIBackupAdapterStatus status;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) NSDate *lastBackupDate;
@property (nonatomic, getter = isEnabled) BOOL enabled;

+ (NSDictionary *)backupSettings;
- (BOOL)isEnabledByDefault;
- (BOOL)needsToBeConfigured;
- (void)updateStatus;
- (void)configureInWindow:(NSWindow *)window;

@end
