//
//  HIProfileViewController.h
//  Hive
//
//  Created by Jakub Suder on 30.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIBox.h"
#import "HIContact.h"
#import "HIFlippedView.h"
#import "HIProfileTabBarController.h"
#import "HIProfileTabView.h"
#import "HITextField.h"
#import "HIViewController.h"

/*
 Manages the contact view that shows information about a selected contact. Includes a tab bar and two tabs with
 transactions list and contact's info. Also used for the user's own profile, though in that case the tab bar is
 hidden and only the contact info panel is visible.
 */

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
