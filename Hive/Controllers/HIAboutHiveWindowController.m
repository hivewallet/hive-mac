//
//  HIAboutHiveWindowController.m
//  Hive
//
//  Created by Jakub Suder on 18.02.2014.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HIAboutHiveWindowController.h"
#import "HILicenseInfoPanelController.h"

@interface HIAboutHiveWindowController ()

@property (strong) IBOutlet NSTextView *creditsBox;
@property (weak) IBOutlet NSTextField *versionField;
@property (weak) IBOutlet NSTextField *copyrightField;
@property (strong) HILicenseInfoPanelController *licenseInfoPanel;

@end

@implementation HIAboutHiveWindowController

- (id)init {
    self = [self initWithWindowNibName:self.className];
    return self;
}

- (void)awakeFromNib {
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = [bundle infoDictionary];
    self.versionField.stringValue = [NSString stringWithFormat:@"Version %@ (%@)",
                                     info[@"CFBundleShortVersionString"],
                                     info[@"CFBundleVersion"]];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit fromDate:[NSDate date]];
    self.copyrightField.stringValue = [NSString stringWithFormat:@"Copyright © %ld hivewallet.com", components.year];

    NSData *creditsFile = [NSData dataWithContentsOfFile:[bundle pathForResource:@"Credits" ofType:@"rtf"]];
    NSAttributedString *credits = [[NSAttributedString alloc] initWithRTF:creditsFile documentAttributes:nil];
    [self.creditsBox.textStorage setAttributedString:credits];

    [self.window center];
}

- (IBAction)showLicenseInfo:(id)sender {
    if (!self.licenseInfoPanel) {
        self.licenseInfoPanel = [HILicenseInfoPanelController new];
    }

    [self.licenseInfoPanel showWindow:sender];
}

@end
