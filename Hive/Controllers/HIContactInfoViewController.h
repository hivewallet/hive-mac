//
//  HIContactInfoViewController.h
//  Hive
//
//  Created by Jakub Suder on 24.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HIBox;
@class HITextField;
@class HIViewController;

/*
 Manages the contact info panel shown in the left tab of the contact view and in the user's profile view.
 */

@interface HIContactInfoViewController : NSViewController

@property (weak) IBOutlet HIBox *addressBoxView;
@property (weak) IBOutlet HITextField *profileEmailField;
@property (weak) IBOutlet NSScrollView *profileScrollView;
@property (weak) IBOutlet NSView *profileScrollContent;
@property (weak) IBOutlet NSButton *editButton;

- (id)initWithParent:(HIViewController *)parent;
- (IBAction)editButtonClicked:(NSButton *)sender;
- (void)configureViewForContact:(HIContact *)contact;

@end
