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

static const NSInteger AddressFieldTag = 2;


@interface HIContactInfoViewController () {
    id<HIPerson> _contact;
    HIViewController *_parent;
}

@end

@implementation HIContactInfoViewController

- (id)initWithParent:(HIViewController *)parent {
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

    [self configureScrollView];

    [self.profileEmailField setValueAndRecalc:((_contact.email.length > 0) ? _contact.email : @"")];

    self.addressBoxView.addresses = _contact.addresses.allObjects;
    self.addressBoxView.observingWallet = [_contact isKindOfClass:[HIProfile class]];
    self.addressBoxView.showsQRCode = [_contact isKindOfClass:[HIProfile class]];
}

- (void)configureScrollView {
    NSRect f = self.profileScrollContent.frame;
    f.size.width = self.profileScrollView.frame.size.width;
    f.size.height = 161 + 60 * _contact.addresses.count;
    self.profileScrollContent.frame = f;
    [self.profileScrollView setDocumentView:self.profileScrollContent];
}


@end
