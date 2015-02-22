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

@property (nonatomic, weak) IBOutlet NSImageView *twitterGeneralIcon;
@property (nonatomic, weak) IBOutlet NSImageView *twitterMacIcon;
@property (nonatomic, weak) IBOutlet NSImageView *githubIcon;
@property (nonatomic, weak) IBOutlet NSImageView *websiteIcon;

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
    iconFactory.size = self.twitterGeneralIcon.frame.size.width;

    self.twitterGeneralIcon.image = [iconFactory createImageForIcon:NIKFontAwesomeIconTwitter];
    self.twitterMacIcon.image = [iconFactory createImageForIcon:NIKFontAwesomeIconTwitter];
    self.githubIcon.image = [iconFactory createImageForIcon:NIKFontAwesomeIconGithub];
    self.websiteIcon.image = [iconFactory createImageForIcon:NIKFontAwesomeIconGlobe];

    self.twitterGeneralIcon.imageFrameStyle = NSImageFrameNone;
    self.twitterMacIcon.imageFrameStyle = NSImageFrameNone;
    self.githubIcon.imageFrameStyle = NSImageFrameNone;
    self.websiteIcon.imageFrameStyle = NSImageFrameNone;

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

- (IBAction)openGitHubProfile:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://github.com/hivewallet"]];
}

@end
