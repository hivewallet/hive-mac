//
//  HIWizardCompletedViewController.m
//  Hive
//
//  Created by Nikolaj Schumacher on 2014-01-19.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory+OSX.h>
#import "HIWizardCompletedViewController.h"

@implementation HIWizardCompletedViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        self.title = NSLocalizedString(@"Start!", @"Wizard completed page title");
    }

    return self;
}

- (void)awakeFromNib {
    NIKFontAwesomeIconFactory *iconFactory = [[NIKFontAwesomeIconFactory alloc] init];
    iconFactory.size = self.twitterGeneralIcon.frame.size.width;
    iconFactory.colors = @[[NSColor colorWithCalibratedRed:85/255.0 green:172/255.0 blue:238/255.0 alpha:1.0]];

    self.twitterGeneralIcon.image = [iconFactory createImageForIcon:NIKFontAwesomeIconTwitter];
    self.twitterMacIcon.image = [iconFactory createImageForIcon:NIKFontAwesomeIconTwitter];

    self.twitterGeneralIcon.imageFrameStyle = NSImageFrameNone;
    self.twitterMacIcon.imageFrameStyle = NSImageFrameNone;

    self.twitterGeneralLink.underlineStyle = HILinkTextFieldUnderlineStyleUsername;
    self.twitterMacLink.underlineStyle = HILinkTextFieldUnderlineStyleUsername;
}

@end
