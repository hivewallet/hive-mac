//
//  HIHiveWebWindowController.m
//  Hive
//
//  Created by Jakub Suder on 04/11/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HIHiveWebWindowController.h"

NSString * const HiveWebAnnouncementDisplayedKey = @"HiveWebAnnouncementDisplayed";

@implementation HIHiveWebWindowController

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
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:HiveWebAnnouncementDisplayedKey];
    [self close];
}

@end
