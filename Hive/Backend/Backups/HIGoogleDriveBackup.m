//
//  HIGoogleDriveBackup.m
//  Hive
//
//  Created by Jakub Suder on 22/07/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HIGoogleDriveBackup.h"


@implementation HIGoogleDriveBackup

#pragma mark - Superclass method overrides

- (NSString *)name {
    return @"gdrive";
}

- (NSString *)displayedName {
    return @"Google Drive";
}

- (NSImage *)icon {
    return [NSImage imageNamed:@"google-drive-128"];
}

- (CGFloat)iconSize {
    return 32.0;
}

- (BOOL)isEnabledByDefault {
    return NO;
}

- (NSString *)syncingAppId {
    return @"com.google.GoogleDrive";
}

- (NSString *)errorDomain {
    return @"HIGoogleDriveBackupError";
}

- (NSString *)errorTitleForSelectedFolderOutsideSyncFolder {
    return NSLocalizedString(@"Selected directory is outside Google Drive folder.",
                             @"Google Drive invalid folder alert title");
}

- (NSString *)errorMessageForSelectedFolderOutsideSyncFolder {
    return NSLocalizedString(@"You need to choose or create a directory inside your Google Drive folder.",
                             @"Google Drive invalid folder alert details");
}

- (NSString *)errorMessageForAppNotRunning {
    return NSLocalizedString(@"Google Drive isn't running", @"Backup error message");
}

- (NSString *)errorTitleForAppNotInstalled {
    return NSLocalizedString(@"Google Drive folder not found.",
                             @"Google Drive no backup folder alert title");
}

- (NSString *)errorMessageForAppNotInstalled {
    return NSLocalizedString(@"You must install Google Drive first (see https://www.google.com/intl/en/drive/download).",
                             @"Google Drive no backup folder alert details");
}

- (NSString *)promptMessageForChooseBackupFolder {
    return NSLocalizedString(@"Choose a directory inside Google Drive folder where the backup should be saved:", nil);
}

- (NSArray *)syncFolders {
    NSString *googleDriveFolder = [self syncFolderFromDetectionScript:@"get_gdrive_folder"];

    return googleDriveFolder ? @[googleDriveFolder] : @[];
}

- (NSString *)defaultBackupFolder {
    NSString *googleDriveFolder = [[self existingSyncFolders] firstObject];

    if (googleDriveFolder) {
        return [googleDriveFolder stringByAppendingPathComponent:[self backupFolderName]];
    } else {
        return nil;
    }
}

@end
