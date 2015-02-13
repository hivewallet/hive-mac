//
//  HIAboutHiveWindowController.m
//  Hive
//
//  Created by Jakub Suder on 18.02.2014.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory+OSX.h>
#import "HIAboutHiveWindowController.h"
#import "HIBitcoinURIService.h"
#import "HILicenseInfoPanelController.h"

@interface HIAboutHiveWindowController ()

@property (nonatomic, strong) IBOutlet NSTextView *creditsBox;  // NSTextView doesn't support weak references
@property (nonatomic, weak) IBOutlet NSTextField *versionField;
@property (nonatomic, weak) IBOutlet NSTextField *copyrightField;
@property (nonatomic, weak) IBOutlet NSButton *twitterButton;
@property (nonatomic, weak) IBOutlet NSButton *facebookButton;
@property (nonatomic, weak) IBOutlet NSButton *githubButton;

@property (nonatomic, strong) HILicenseInfoPanelController *licenseInfoPanel;

@end

@implementation HIAboutHiveWindowController

- (instancetype)init {
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
    NSString *year = [NSString stringWithFormat:@"%ld", components.year];
    self.copyrightField.stringValue = [self.copyrightField.stringValue stringByReplacingOccurrencesOfString:@"20xx"
                                                                                                 withString:year];

    NSData *creditsFile = [NSData dataWithContentsOfFile:[bundle pathForResource:@"Credits" ofType:@"rtf"]];
    NSAttributedString *credits = [[NSAttributedString alloc] initWithRTF:creditsFile documentAttributes:nil];
    [self.creditsBox.textStorage setAttributedString:credits];

    NIKFontAwesomeIconFactory *iconFactory = [[NIKFontAwesomeIconFactory alloc] init];
    iconFactory.size = self.twitterButton.frame.size.width;

    self.twitterButton.image = [iconFactory createImageForIcon:NIKFontAwesomeIconTwitter];
    self.facebookButton.image = [iconFactory createImageForIcon:NIKFontAwesomeIconFacebookSquare];
    self.githubButton.image = [iconFactory createImageForIcon:NIKFontAwesomeIconGithub];

    [self.window center];
}

- (IBAction)showLicenseInfo:(id)sender {
    if (!self.licenseInfoPanel) {
        self.licenseInfoPanel = [HILicenseInfoPanelController new];
    }

    [self.licenseInfoPanel showWindow:sender];
}

- (IBAction)openTwitterProfile:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://twitter.com/hivewallet"]];
}

- (IBAction)openFacebookProfile:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://facebook.com/hivewallet"]];
}

- (IBAction)openGitHubProfile:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://github.com/hivewallet"]];
}

@end
