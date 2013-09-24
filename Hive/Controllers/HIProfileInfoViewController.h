//
//  HIProfileInfoViewController.h
//  Hive
//
//  Created by Jakub Suder on 24.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HIBox;
@class HITextField;
@class HIViewController;

@interface HIProfileInfoViewController : NSViewController

@property (weak) IBOutlet HIBox *addressBoxView;
@property (weak) IBOutlet HITextField *profileEmailField;
@property (weak) IBOutlet NSScrollView *profileScrollView;
@property (weak) IBOutlet NSView *profileScrollContent;

- (id)initWithParent:(HIViewController *)parent;
- (IBAction)editButtonClicked:(NSButton *)sender;
- (void)configureViewForContact:(HIContact *)contact;
- (void)configureViewForOwner;

@end
