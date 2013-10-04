//
//  HIProfileViewController.h
//  Hive
//
//  Created by Jakub Suder on 30.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIViewController.h"
#import "HIContact.h"
#import "HIProfileTabBarController.h"
#import "HIProfileTabView.h"
#import "HIFlippedView.h"
#import "HIBox.h"
#import "HITextField.h"

@interface HIProfileViewController : HIViewController <HIProfileTabBarControllerDelegate>

@property (strong) IBOutlet NSImageView *photoView;
@property (strong) IBOutlet NSImageView *bitcoinSymbol;
@property (strong) IBOutlet NSTextField *nameLabel;
@property (strong) IBOutlet NSTextField *balanceLabel;
@property (strong) IBOutlet NSButton *sendBitcoinButton;
@property (strong) IBOutlet HIProfileTabView *tabView;
@property (strong) IBOutlet HIProfileTabBarController *tabBarController;
@property (strong) IBOutlet NSView *contentView;

- (id)initWithContact:(HIContact *)aContact;
- (IBAction)sendBitcoinsPressed:(id)sender;

@end
