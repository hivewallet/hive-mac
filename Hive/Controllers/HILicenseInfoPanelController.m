//
//  HILicenseInfoPanelController.m
//  Hive
//
//  Created by Jakub Suder on 18/02/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HILicenseInfoPanelController.h"

@interface HILicenseInfoPanelController ()

@property (strong) IBOutlet NSTextView *licenseTextBox;

@end

@implementation HILicenseInfoPanelController

- (id)init {
    self = [self initWithWindowNibName:self.className];
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.window center];

    NSBundle *bundle = [NSBundle mainBundle];
    NSData *licenseFile = [NSData dataWithContentsOfFile:[bundle pathForResource:@"Licenses" ofType:@"rtf"]];
    NSAttributedString *licenses = [[NSAttributedString alloc] initWithRTF:licenseFile documentAttributes:nil];
    [self.licenseTextBox.textStorage setAttributedString:licenses];
}

@end
