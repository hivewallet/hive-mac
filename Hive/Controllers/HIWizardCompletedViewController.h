//
//  HIWizardCompletedViewController.h
//  Hive
//
//  Created by Nikolaj Schumacher on 2014-01-19.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HILinkTextField.h"
#import "HIWizardViewController.h"

@interface HIWizardCompletedViewController : HIWizardViewController

@property (nonatomic, weak) IBOutlet NSImageView *twitterGeneralIcon;
@property (nonatomic, weak) IBOutlet NSImageView *twitterMacIcon;

@property (nonatomic, weak) IBOutlet HILinkTextField *twitterGeneralLink;
@property (nonatomic, weak) IBOutlet HILinkTextField *twitterMacLink;

@end
