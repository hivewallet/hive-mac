//
//  HILocalBackup.m
//  Hive
//
//  Created by Jakub Suder on 13/02/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import <BitcoinJKit/HIBitcoinManager.h>
#import "BCClient.h"
#import "HILocalBackup.h"

NSString * const HILocalBackupError = @"HILocalBackupError";
const NSInteger HILocalBackupWalletNotEncrypted = -1;
const NSInteger HILocalBackupFailed = -2;


@implementation HILocalBackup

- (id)init {
    self = [super init];

    if (self) {
        self.status = HIBackupStatusWaiting;
        self.error = nil;
    }

    return self;
}


#pragma mark - Superclass method overrides

- (NSString *)name {
    return @"local";
}

- (NSString *)displayedName {
    return @"Local Backup";
}

- (NSImage *)icon {
    return nil;
}

- (BOOL)isEnabledByDefault {
    return YES;
}

- (BOOL)requiresEncryption {
    return YES;
}

- (BOOL)canBeConfigured {
    return NO;
}

- (BOOL)needsToBeConfigured {
    return NO;
}

- (BOOL)isVisible {
    return NO;
}

- (void)updateStatus {
}


#pragma mark - Performing backup

- (void)performBackup {
    if (![[BCClient sharedClient] isWalletPasswordProtected]) {
        // don't create unencrypted backups since the user won't even know they're there
        self.status = HIBackupStatusFailure;
        self.error = BackupError(HILocalBackupError, HILocalBackupWalletNotEncrypted, @"Wallet is not encrypted");
        return;
    }

    NSString *addressPrefix = [[[BCClient sharedClient] walletHash] substringToIndex:5];
    NSURL *localDirectory = [[BCClient sharedClient] bitcoinjDirectory];

    // always create one copy at startup
    NSString *latestBackupFileName = [NSString stringWithFormat:@"backup-%@.wallet", addressPrefix];
    NSURL *latestBackupFile = [localDirectory URLByAppendingPathComponent:latestBackupFileName];

    if (![self backUpWalletToFile:latestBackupFile]) {
        return;
    }

    // also keep one initial copy of the wallet in case it gets corrupted later
    NSString *initialBackupFileName = [NSString stringWithFormat:@"backup-%@-1.wallet", addressPrefix];
    NSURL *initialBackupFile = [localDirectory URLByAppendingPathComponent:initialBackupFileName];

    if (![[NSFileManager defaultManager] fileExistsAtPath:initialBackupFile.path]) {
        if (![self backUpWalletToFile:initialBackupFile]) {
            return;
        }
    }

    self.status = HIBackupStatusUpToDate;
}

- (BOOL)backUpWalletToFile:(NSURL *)backupFile {
    NSError *error = nil;

    HILogInfo(@"Backing up wallet file to %@", backupFile);
    [[HIBitcoinManager defaultManager] exportWalletTo:backupFile error:&error];

    if (error) {
        self.status = HIBackupStatusFailure;
        self.error = BackupError(HILocalBackupError, HILocalBackupFailed, error.localizedFailureReason);
        return NO;
    }

    return YES;
}

@end
