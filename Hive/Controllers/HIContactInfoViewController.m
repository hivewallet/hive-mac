//
//  HIContactInfoViewController.m
//  Hive
//
//  Created by Jakub Suder on 24.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HIAddress.h"
#import "HIAddressesBox.h"
#import "HIContact.h"
#import "HIContactInfoViewController.h"
#import "HICopyView.h"
#import "HINavigationController.h"
#import "HINewContactViewController.h"
#import "HIPerson.h"
#import "HIProfile.h"
#import "HIViewController.h"
#import "NSColor+Hive.h"


@interface HIContactInfoViewController () {
    id<HIPerson> _contact;
    HIViewController *_parent;
}

@property (nonatomic, weak) IBOutlet HIAddressesBox *addressBoxView;
@property (nonatomic, weak) IBOutlet NSTextField *profileEmailField;
@property (nonatomic, weak) IBOutlet NSScrollView *profileScrollView;
@property (nonatomic, weak) IBOutlet NSView *profileScrollContent;
@property (nonatomic, weak) IBOutlet NSButton *editButton;

@end

@implementation HIContactInfoViewController

- (instancetype)initWithParent:(HIViewController *)parent {
    self = [super initWithNibName:@"HIContactInfoViewController" bundle:nil];

    if (self) {
        _parent = parent;
    }
    
    return self;
}

- (IBAction)editButtonClicked:(NSButton *)sender {
    HINewContactViewController *vc = [HINewContactViewController new];
    vc.contact = _contact;

    if ([_contact isKindOfClass:[HIContact class]]) {
        vc.title = NSLocalizedString(@"Edit contact", @"Page title when editing contact's info");
    } else {
        vc.title = NSLocalizedString(@"Edit profile", @"Page title when editing your own profile info");
    }

    [_parent.navigationController pushViewController:vc animated:YES];
}

- (void)configureViewForContact:(id<HIPerson>)contact {
    _contact = contact;

    self.profileEmailField.stringValue = _contact.email ?: @"";

    self.addressBoxView.addresses = _contact.addresses.allObjects;
    self.addressBoxView.observingWallet = [_contact isKindOfClass:[HIProfile class]];
    self.addressBoxView.showsQRCode = [_contact isKindOfClass:[HIProfile class]];

    [self configureScrollView];
}

- (void)configureScrollView {
    NSRect f = self.profileScrollContent.frame;
    f.size.width = self.profileScrollView.frame.size.width;
    f.size.height = 161 + self.addressBoxView.intrinsicContentSize.height;
    self.profileScrollContent.frame = f;
    [self.profileScrollView setDocumentView:self.profileScrollContent];
}


@end
