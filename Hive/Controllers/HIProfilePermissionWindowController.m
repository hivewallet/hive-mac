//
//  HIProfilePermissionWindowController.m
//  Hive
//
//  Created by Jakub Suder on 25/02/15.
//  Copyright (c) 2015 Hive Developers. All rights reserved.
//

#import "HIProfilePermissionWindowController.h"

NSString * const SUSendProfileInfoKey = @"SUSendProfileInfo";


@implementation HIProfilePermissionWindowController

- (instancetype)init {
    return [self initWithWindowNibName:self.className];
}

- (void)windowDidLoad {
    [super windowDidLoad];

    [self.window center];
}

- (void)cancel:(id)sender {
    [self close];
}

- (IBAction)allowButtonPressed:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:SUSendProfileInfoKey];
    [self close];
}

- (IBAction)dontAllowButtonPressed:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:SUSendProfileInfoKey];
    [self close];
}

- (IBAction)moreInfoButtonPressed:(id)sender {
    NSURL *wiki = [NSURL URLWithString:@"https://github.com/sparkle-project/Sparkle/wiki/System-Profiling"];
    [[NSWorkspace sharedWorkspace] openURL:wiki];
}

@end
