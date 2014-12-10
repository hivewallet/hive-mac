//
//  HIHiveWebWindowController.m
//  Hive
//
//  Created by Jakub Suder on 04/11/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HIHiveWebWindowController.h"
#import "HILinkTextField.h"

NSString * const HiveWebAnnouncementDisplayedKey = @"HiveWebAnnouncementDisplayed";

@interface HIHiveWebWindowController ()

@property (nonatomic, weak) IBOutlet NSButton *iphoneImage;
@property (nonatomic, weak) IBOutlet HILinkTextField *hivewalletComLink;

@end

@implementation HIHiveWebWindowController

- (instancetype)init {
    return [self initWithWindowNibName:self.className];
}

- (void)windowDidLoad {
    [super windowDidLoad];

    [self.window center];

    [self.iphoneImage.cell setHighlightsBy:NSNoCellMask];
}

- (IBAction)cancelPressed:(id)sender {
    [self close];
}

- (IBAction)okPressed:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:HiveWebAnnouncementDisplayedKey];
    [self close];
}

- (IBAction)iphonePressed:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:self.hivewalletComLink.href]];
}

@end
