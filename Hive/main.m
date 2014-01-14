//
//  main.m
//  Hive
//
//  Created by Bazyli Zygan on 11.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

void migratePreferences();

int main(int argc, char *argv[]) {
    migratePreferences();
    return NSApplicationMain(argc, (const char **)argv);
}

void migratePreferences() {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *libraryDir = [fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask][0];
    NSURL *preferencesDir = [libraryDir URLByAppendingPathComponent:@"Preferences"];
    NSURL *oldPreferencesFile = [preferencesDir URLByAppendingPathComponent:@"com.grabhive.Hive.plist"];
    if ([fileManager fileExistsAtPath:oldPreferencesFile.path]) {
        NSURL *newPreferencesFile = [preferencesDir URLByAppendingPathComponent:@"com.hivewallet.Hive.plist"];
        if (![fileManager moveItemAtURL:oldPreferencesFile toURL:newPreferencesFile error:NULL]) {
            HILogError(@"Could not migrate preference file from %@ to %@.", oldPreferencesFile, newPreferencesFile);
        }
    }
}
