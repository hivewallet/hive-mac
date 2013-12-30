//
//  HIDropboxBackup.m
//  Hive
//
//  Created by Jakub Suder on 23.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIDropboxBackup.h"

static NSString * const LocationKey = @"location";

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
    return 44.0;
}

- (BOOL)isEnabledByDefault {
    return NO;
}

- (BOOL)needsToBeConfigured {
    return YES;
}

- (void)updateStatus {
    // TODO

    if (!self.enabled) {
        self.status = HIBackupStatusDisabled;
    } else {
        self.status = HIBackupStatusUpToDate;
    }
}


#pragma mark - Configuring backup

- (NSString *)dropboxFolder {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Dropbox"];
}

- (NSString *)backupLocation {
    return self.adapterSettings[LocationKey];
}

- (void)setBackupLocation:(NSString *)location {
    NSMutableDictionary *adapterSettings = self.adapterSettings;
    [adapterSettings setObject:location forKey:LocationKey];
    [self saveAdapterSettings:adapterSettings];
}

- (void)configureInWindow:(NSWindow *)window {
    NSString *dropboxFolder = [self dropboxFolder];
    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:dropboxFolder isDirectory:&isDirectory];

    if (!exists || !isDirectory) {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Dropbox folder not found",
                                                                         @"Dropbox no backup folder alert title")
                                         defaultButton:NSLocalizedString(@"OK", @"OK button title")
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"You must install Dropbox first (see www.dropbox.com).",
                                                                         @"Dropbox no backup folder alert details")];
        [alert beginSheetModalForWindow:window completionHandler:nil];
        return;
    }

    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.prompt = NSLocalizedString(@"Choose", @"Dropbox folder save panel confirmation button");
    panel.message = NSLocalizedString(@"Choose a directory inside Dropbox folder where the backup should be saved:", nil);
    panel.directoryURL = [NSURL URLWithString:dropboxFolder];
    panel.canChooseDirectories = YES;
    panel.canCreateDirectories = YES;
    panel.canChooseFiles = NO;

    [panel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [self backupFolderSelected:panel.URL.path inWindow:window];
        }
    }];
}

- (void)backupFolderSelected:(NSString *)selectedDirectory inWindow:(NSWindow *)window {
    if (![selectedDirectory hasPrefix:[self dropboxFolder]]) {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Selected directory is outside Dropbox folder",
                                                                         @"Dropbox invalid folder alert title")
                                         defaultButton:NSLocalizedString(@"OK", @"OK button title")
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"You need to choose or create a directory "
                                                                         @"inside your Dropbox folder.",
                                                                         @"Dropbox invalid folder alert details")];

        [alert beginSheetModalForWindow:window completionHandler:nil];
        return;
    }

    [self setBackupLocation:selectedDirectory];

    self.enabled = YES;
}

@end
