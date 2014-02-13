//
//  HIBackupAdapter.h
//  Hive
//
//  Created by Jakub Suder on 23.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BackupError(domain, errorCode, reason) [NSError errorWithDomain:domain \
                                                                   code:errorCode \
                                                               userInfo:@{NSLocalizedFailureReasonErrorKey: \
                                                                          (reason)}];

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

extern NSString *HIBackupStatusTextDisabled;
extern NSString *HIBackupStatusTextUpToDate;
extern NSString *HIBackupStatusTextWaiting;
extern NSString *HIBackupStatusTextOutdated;
extern NSString *HIBackupStatusTextFailure;


@interface HIBackupAdapter : NSObject

@property (readonly) NSString *name;
@property (readonly) NSString *displayedName;
@property (readonly) NSString *errorMessage;
@property (readonly) NSImage *icon;
@property (readonly) CGFloat iconSize;
@property (readonly) BOOL canBeConfigured;
@property (readonly) BOOL needsToBeConfigured;
@property (readonly) BOOL requiresEncryption;
@property (readonly, getter = isEnabledByDefault) BOOL enabledByDefault;

@property (nonatomic) HIBackupAdapterStatus status;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSDate *lastBackupDate;
@property (nonatomic, getter = isEnabled) BOOL enabled;

+ (NSDictionary *)backupSettings;

- (void)updateStatus;
- (void)performBackup;
- (void)configureInWindow:(NSWindow *)window;

- (NSMutableDictionary *)adapterSettings;
- (void)saveAdapterSettings:(NSDictionary *)settings;

- (NSString *)lastBackupInfo;
- (NSDate *)lastWalletChange;
- (BOOL)updatedAfterLastWalletChange;

@end
