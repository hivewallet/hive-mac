//
//  HIDropboxBackup.m
//  Hive
//
//  Created by Jakub Suder on 23.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIDropboxBackup.h"


@implementation HIDropboxBackup

#pragma mark - Superclass method overrides

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
    return 48.0;
}

- (BOOL)isEnabledByDefault {
    return NO;
}

- (NSString *)syncingAppId {
    return @"com.getdropbox.dropbox";
}

- (NSString *)errorDomain {
    return @"HIDropboxBackupError";
}

- (NSString *)errorTitleForSelectedFolderOutsideSyncFolder {
    return NSLocalizedString(@"Selected directory is outside Dropbox folder.",
                             @"Dropbox invalid folder alert title");
}

- (NSString *)errorMessageForSelectedFolderOutsideSyncFolder {
    return NSLocalizedString(@"You need to choose or create a directory inside your Dropbox folder.",
                             @"Dropbox invalid folder alert details");
}

- (NSString *)errorMessageForAppNotRunning {
    return NSLocalizedString(@"Dropbox isn't running", @"Backup error message");
}

- (NSString *)errorTitleForAppNotInstalled {
    return NSLocalizedString(@"Dropbox folder not found.",
                             @"Dropbox no backup folder alert title");
}

- (NSString *)errorMessageForAppNotInstalled {
    return NSLocalizedString(@"You must install Dropbox first (see www.dropbox.com).",
                             @"Dropbox no backup folder alert details");
}

- (NSString *)promptMessageForChooseBackupFolder {
    return NSLocalizedString(@"Choose a directory inside Dropbox folder where the backup should be saved:", nil);
}

- (NSArray *)syncFolders {
    NSString *configDir = [NSHomeDirectory() stringByAppendingPathComponent:@".dropbox"];
    NSString *jsonFile = [configDir stringByAppendingPathComponent:@"info.json"];

    if ([[NSFileManager defaultManager] fileExistsAtPath:jsonFile]) {
        NSError *error = nil;
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonFile];

        if (!jsonData) {
            HILogWarn(@"Dropbox config file %@ couldn't be read.", jsonFile);
            return nil;
        }

        id json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];

        if (!json) {
            HILogWarn(@"Dropbox config file %@ couldn't be parsed: %@.", jsonFile, error);
            return nil;
        }

        return [[json allValues] valueForKey:@"path"];
    } else {
        HILogWarn(@"Dropbox config file %@ doesn't exist.", jsonFile);
        return nil;
    }
}

- (NSString *)defaultBackupFolder {
    NSArray *dropboxFolders = [self existingSyncFolders];

    if (dropboxFolders.count == 1) {
        NSString *hiveDirectoryName = [self backupFolderName];
        NSString *dropboxFolder = [dropboxFolders firstObject];
        NSString *appsFolder = [dropboxFolder stringByAppendingPathComponent:@"Apps"];
        BOOL isDirectory;

        if ([[NSFileManager defaultManager] fileExistsAtPath:appsFolder isDirectory:&isDirectory] && isDirectory) {
            return [appsFolder stringByAppendingPathComponent:hiveDirectoryName];
        } else {
            return [dropboxFolder stringByAppendingPathComponent:hiveDirectoryName];
        }
    } else {
        return nil;
    }
}

@end
