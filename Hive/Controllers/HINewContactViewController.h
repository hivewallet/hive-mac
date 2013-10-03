//
//  HINewContactViewController.h
//  Hive
//
//  Created by Bazyli Zygan on 02.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIViewController.h"
#import "HITextField.h"
#import "HIBox.h"
#import "HIContact.h"

@interface HINewContactViewController : HIViewController
@property (strong) IBOutlet HITextField *firstnameField;
@property (strong) IBOutlet HITextField *lastnameField;
@property (strong) IBOutlet HITextField *emailField;
@property (strong) IBOutlet NSView *scrollContent;
@property (weak) IBOutlet HIBox *walletsView;
@property (weak) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet NSView *footerView;
@property (weak) IBOutlet NSButton *addAddressButton;
@property (weak) IBOutlet NSButton *removeContactButton;

@property (strong) HIContact *contact;

@property (strong) IBOutlet NSImageView *avatarView;

- (IBAction)doneClicked:(NSButton *)sender;
- (IBAction)removeContactClicked:(NSButton *)sender;
- (IBAction)addAddressClicked:(NSButton *)sender;

@end
