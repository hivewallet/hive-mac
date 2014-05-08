//
//  HIContactInfoViewController.h
//  Hive
//
//  Created by Jakub Suder on 24.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

@class HIBox;
@class HIViewController;
@protocol HIPerson;
@class HIAddressesBox;

/*
 Manages the contact info panel shown in the left tab of the contact view and in the user's profile view.
 */

@interface HIContactInfoViewController : NSViewController

@property (weak) IBOutlet HIAddressesBox *addressBoxView;
@property (weak) IBOutlet NSTextField *profileEmailField;
@property (weak) IBOutlet NSScrollView *profileScrollView;
@property (weak) IBOutlet NSView *profileScrollContent;
@property (weak) IBOutlet NSButton *editButton;

- (id)initWithParent:(HIViewController *)parent;
- (IBAction)editButtonClicked:(NSButton *)sender;
- (void)configureViewForContact:(id<HIPerson>)contact;

@end
