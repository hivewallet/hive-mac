//
//  HIProfileInfoViewController.m
//  Hive
//
//  Created by Jakub Suder on 24.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HIAddress.h"
#import "HIContact.h"
#import "HICopyView.h"
#import "HINavigationController.h"
#import "HINewContactViewController.h"
#import "HIProfileInfoViewController.h"
#import "HIViewController.h"
#import "NSColor+NativeColor.h"

static const NSInteger AddressFieldTag = 2;


@interface HIProfileInfoViewController () {
    HIContact *_contact;
    HICopyView *_ownerCopyView;
    HIViewController *_parent;
}

@end

@implementation HIProfileInfoViewController

- (id)initWithParent:(HIViewController *)parent
{
    self = [super initWithNibName:@"HIProfileInfoViewController" bundle:nil];

    if (self)
    {
        _parent = parent;
    }
    
    return self;
}

- (IBAction)editButtonClicked:(NSButton *)sender
{
    if (_contact)
    {
        HINewContactViewController *vc = [HINewContactViewController new];
        vc.contact = _contact;
        vc.title = NSLocalizedString(@"Edit contact", nil);
        [_parent.navigationController pushViewController:vc animated:YES];
    }
}

- (void)configureViewForContact:(HIContact *)contact
{
    _contact = contact;

    [self configureScrollView];

    if (_contact.email.length > 0)
    {
        [self.profileEmailField setStringValue:_contact.email];
        [self.profileEmailField recalcForString:_contact.email];
    }

    // configure box size
    NSRect f = self.addressBoxView.frame;
    f.size.height = 60 * _contact.addresses.count;
    f.origin.y = 116;
    self.addressBoxView.frame = f;

    // clean up the box
    [[self.addressBoxView.subviews copy] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    // fill it with new address views
    NSInteger index = 0;

    for (HIAddress *address in _contact.addresses)
    {
        if (index > 0)
        {
            [self.addressBoxView addSubview:[self addressSeparatorViewAtIndex:index]];
        }

        [self.addressBoxView addSubview:[self copyViewAtIndex:index forAddress:address]];

        index++;
    }
}

- (NSView *)addressSeparatorViewAtIndex:(NSInteger)index
{
    NSRect frame = NSMakeRect(1, 60 * index, self.addressBoxView.bounds.size.width - 2, 1);
    NSView *separator = [[NSView alloc] initWithFrame:frame];

    separator.wantsLayer = YES;
    separator.layer.backgroundColor = [[NSColor colorWithCalibratedWhite:0.5 alpha:0.5] NativeColor];
    separator.autoresizingMask = NSViewMinYMargin | NSViewWidthSizable;

    return separator;
}

- (HICopyView *)copyViewAtIndex:(NSInteger)index forAddress:(HIAddress *)address
{
    // build the copy view
    NSRect copyViewFrame = NSMakeRect(0, index * 60, self.addressBoxView.bounds.size.width, 60);
    HICopyView *copyView = [[HICopyView alloc] initWithFrame:copyViewFrame];
    copyView.contentToCopy = address.address;

    // build the name subview
    NSRect nameFieldFrame = NSMakeRect(10, 30, self.addressBoxView.bounds.size.width - 20, 21);
    NSTextField *nameField = [[NSTextField alloc] initWithFrame:nameFieldFrame];
    [nameField.cell setLineBreakMode:NSLineBreakByTruncatingTail];
    [nameField setAutoresizingMask:(NSViewMinYMargin | NSViewWidthSizable)];
    [nameField setFont:[NSFont fontWithName:@"Helvetica-Bold" size:14]];
    [nameField setEditable:NO];
    [nameField setSelectable:NO];
    [nameField setBordered:NO];
    [nameField setBackgroundColor:[NSColor clearColor]];

    if (address)
    {
        nameField.stringValue = address.caption;
    }
    else
    {
        nameField.stringValue = NSLocalizedString(@"Main address", @"Main address caption string for profiles");
    }

    // build the address subview
    NSRect addressFieldFrame = NSMakeRect(10, 7, self.addressBoxView.bounds.size.width - 20, 21);
    NSTextField *addressField = [[NSTextField alloc] initWithFrame:addressFieldFrame];
    [addressField.cell setLineBreakMode:NSLineBreakByTruncatingTail];
    [addressField.cell setSelectable:YES];
    [addressField setEditable:NO];
    [addressField setSelectable:NO];
    [addressField setBordered:NO];
    [addressField setBackgroundColor:[NSColor clearColor]];
    [addressField setAutoresizingMask:(NSViewMinYMargin | NSViewWidthSizable)];
    [addressField setFont:[NSFont fontWithName:@"Helvetica" size:12]];
    [addressField setTextColor:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0]];
    [addressField setTag:AddressFieldTag];

    if (address)
    {
        [addressField setStringValue:address.address];
    }

    // put everything together
    [copyView addSubview:nameField];
    [copyView addSubview:addressField];

    nameField.nextKeyView = addressField;
    addressField.nextKeyView = nameField;

    [nameField awakeFromNib];
    [addressField awakeFromNib];

    return copyView;
}

- (void)configureViewForOwner
{
    _contact = nil;

    [self configureScrollView];

    NSRect f = self.addressBoxView.frame;
    f.size.height += 60;
    f.origin.y -= 60;
    self.addressBoxView.frame = f;

    _ownerCopyView = [self copyViewAtIndex:0 forAddress:nil];
    [self.addressBoxView addSubview:_ownerCopyView];

    [[BCClient sharedClient] addObserver:self
                              forKeyPath:@"walletHash"
                                 options:NSKeyValueObservingOptionInitial
                                 context:NULL];
}

- (void)configureScrollView
{
    NSRect f = self.profileScrollContent.frame;
    f.size.width = self.profileScrollView.frame.size.width;
    f.size.height = 161 + 60 * (_contact ? _contact.addresses.count : 1);
    self.profileScrollContent.frame = f;
    [self.profileScrollView setDocumentView:self.profileScrollContent];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == [BCClient sharedClient])
    {
        if ([keyPath isEqual:@"walletHash"])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *walletHash = [[BCClient sharedClient] walletHash];

                if (walletHash)
                {
                    _ownerCopyView.contentToCopy = walletHash;
                    [[_ownerCopyView viewWithTag:AddressFieldTag] setStringValue:walletHash];
                }
            });
        }
    }
}

@end
