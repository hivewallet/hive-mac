//
//  HICrowdfundingWindowController.m
//  Hive
//
//  Created by Jakub Suder on 05/03/15.
//  Copyright (c) 2015 Hive Developers. All rights reserved.
//

#import "HICrowdfundingWindowController.h"

NSString * const CrowdfundingAnnouncementDisplayedKey = @"CrowdfundingAnnouncementDisplayed";

@implementation HICrowdfundingWindowController

- (instancetype)init {
    return [self initWithWindowNibName:self.className];
}

- (void)windowDidLoad {
    [super windowDidLoad];

    [self.window center];
}

- (IBAction)cancelPressed:(id)sender {
    [self close];
}

- (IBAction)okPressed:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:CrowdfundingAnnouncementDisplayedKey];
    [self close];
}

- (IBAction)videoImagePressed:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://vimeo.com/119278429"]];
}

@end
