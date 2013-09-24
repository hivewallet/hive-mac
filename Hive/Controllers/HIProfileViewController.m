//
//  HIProfileViewController.m
//  Hive
//
//  Created by Jakub Suder on 30.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIAppDelegate.h"
#import "HIProfileViewController.h"
#import "HISendBitcoinsWindowController.h"
#import "HITextField.h"
#import "NSColor+NativeColor.h"
#import "HIAddress.h"
#import "BCClient.h"
#import "HINewContactViewController.h"
#import "HINavigationController.h"
#import "HICopyView.h"

@interface HIProfileViewController () {
    HIContact *contact;
    NSTextField *_addressField;
    HICopyView  *_copyView;
}

@end

@implementation HIProfileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.iconName = @"your-profile";
        self.title = NSLocalizedString(@"Profile", @"Profile view title string");        
    }
    
    return self;
}

- (id)initWithContact:(HIContact *)aContact {
    self = [super initWithNibName:@"HIProfileViewController" bundle:nil];

    if (self) {
        contact = aContact;
        self.nameLabel.stringValue = contact.name;
        self.photoView.image = contact.avatarImage;
        self.title = contact.name;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactHasChanged:) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)contactHasChanged:(NSNotification *)not
{
    if (!contact)
        return;
    
    NSArray* updatedObjects = [[not userInfo]
                               objectForKey:NSUpdatedObjectsKey];
    
    BOOL itsMe = NO;
    
    for (NSManagedObject *obj in updatedObjects)
    {
        if (obj == contact)
        {
            itsMe = YES;
            break;
        }
    }
    
    if (itsMe)
        [self configureView];
}

- (void)configureView
{
    self.nameLabel.stringValue = contact.name;
    self.photoView.image = contact.avatarImage;
    if (contact.email.length > 0)
    {
        _profileEmailField.stringValue = contact.email;
        [_profileEmailField recalcForString:contact.email];
    }
    
    // Add scroll content
    NSRect f = _profileScrollContent.frame;
    f.size.width = _profileScrollView.frame.size.width;
    f.size.height = 161 + (60 * contact.addresses.count);
    _profileScrollContent.frame = f;
    [_profileScrollView  setDocumentView:_profileScrollContent];
    // First configure box size    
    f = _addressBoxView.frame;
    f.size.height = 60 * contact.addresses.count;
    f.origin.y = 116;//60 * contact.addresses.count;
    _addressBoxView.frame = f;
    

    
    NSArray *svs = [_addressBoxView.subviews copy];
    for (NSView *v in svs)
        [v removeFromSuperview];
    
    int idx = 0;
    for (HIAddress *addr in contact.addresses)
    {
        if (idx > 0)
        {
            NSView *separator = [[NSView alloc] initWithFrame:NSMakeRect(1, (60*idx), _addressBoxView.bounds.size.width-2, 1)];
            
            separator.wantsLayer = YES;
            separator.layer.backgroundColor = [[NSColor colorWithCalibratedWhite:0.5 alpha:0.5] NativeColor];
            separator.autoresizingMask = NSViewMinYMargin | NSViewWidthSizable;
            [_addressBoxView addSubview:separator];
            
        }
        HICopyView *cV = [[HICopyView alloc] initWithFrame:CGRectMake(0, idx*60, _addressBoxView.bounds.size.width, 60)];
        NSTextField *nameField = [[NSTextField alloc] initWithFrame:CGRectMake(10, 30, _addressBoxView.bounds.size.width-20, 21)];
        [[nameField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
        nameField.autoresizingMask = NSViewMinYMargin | NSViewWidthSizable;
        nameField.font = [NSFont fontWithName:@"Helvetica-Bold" size:14];
        [nameField setEditable:NO];
        [nameField setSelectable:NO];
        [nameField setBordered:NO];
        nameField.backgroundColor = [NSColor clearColor];
//        [nameField.cell setPlaceholderString:NSLocalizedString(@"Address caption", @"Address caption field placeholder")];
        
        NSTextField *addressField = [[NSTextField alloc] initWithFrame:CGRectMake(10, 7, _addressBoxView.bounds.size.width-20, 21)];
        [[addressField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
        [addressField setEditable:NO];
        [addressField setSelectable:YES];
        [addressField.cell setSelectable:YES];
        [addressField setBordered:NO];
        addressField.backgroundColor = [NSColor clearColor];
        addressField.autoresizingMask = NSViewMinYMargin | NSViewWidthSizable;
//        [addressField.cell setPlaceholderString:NSLocalizedString(@"Address", @"Address field placeholder")];
        addressField.font = [NSFont fontWithName:@"Helvetica" size:12];
        nameField.nextKeyView = addressField;
        addressField.nextKeyView = nameField;
        [cV addSubview:nameField];
        [cV addSubview:addressField];
        [_addressBoxView addSubview:cV];
        [nameField awakeFromNib];
        [addressField awakeFromNib];
        addressField.textColor = [NSColor colorWithCalibratedWhite:0.5 alpha:1.0];
        nameField.stringValue = addr.caption;
        addressField.stringValue = addr.address;
        cV.contentToCopy = addr.address;
        [addressField setSelectable:NO];
        idx++;
    }
    
}

- (void)loadView {
    [super loadView];
    
    if (contact)
    {
        [self configureView];
    }
    else
    {
        NSRect f = self.nameLabel.frame;
        f.origin.y -= 15;
        self.nameLabel.frame = f;
        
        f = self.contentView.frame;
        f.origin.y = 0;
        f.size.height = self.view.bounds.size.height - 78;
        f.size.width = self.view.bounds.size.width;
        self.contentView.frame = f;
        //NSLog(@"Size is %@", NSStringFromRect(f));
        [self.sendBtcBtn setHidden:YES];
        [self.tabView setHidden:YES];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"firstName"] || [[NSUserDefaults standardUserDefaults] objectForKey:@"lastName"])
            self.nameLabel.stringValue = [NSString stringWithFormat:@"%@ %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"firstName"], [[NSUserDefaults standardUserDefaults] objectForKey:@"lastName"]];
        else
            self.nameLabel.stringValue = NSLocalizedString(@"Anonymous", @"Anonymous username for profile page");
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"avatarData"])
        {
            self.photoView.image = [[NSImage alloc] initWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"avatarData"]];
        }
        else
        {
            self.photoView.image = [NSImage imageNamed:@"avatar-empty"];
        }
        
        f = _profileView.frame;
        f.origin.x = 0;
        f.origin.y = 0;
        f.size.width = _contentView.bounds.size.width;
        f.size.height = _contentView.bounds.size.height;
        _profileView.frame = f;
        
        [_contentView addSubview:_profileView];
        
        // And show our address
        f = _addressBoxView.frame;
        f.size.height += 60;
        f.origin.y -= 60;
        _addressBoxView.frame = f;
        
        HICopyView *cV = [[HICopyView alloc] initWithFrame:CGRectMake(0, 0, _addressBoxView.bounds.size.width, 60)];
        
        NSTextField *nameField = [[NSTextField alloc] initWithFrame:CGRectMake(10, 30, _addressBoxView.bounds.size.width-20, 21)];
        [[nameField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
        [nameField setBordered:NO];
        nameField.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
        nameField.font = [NSFont fontWithName:@"Helvetica-Bold" size:14];
        [nameField setEditable:NO];
        nameField.backgroundColor = [NSColor clearColor];
        
        NSTextField *addressField = [[NSTextField alloc] initWithFrame:CGRectMake(10, 7, _addressBoxView.bounds.size.width-20, 21)];
        [[addressField cell] setLineBreakMode:NSLineBreakByTruncatingTail];        
        [addressField setEditable:NO];
        [addressField setBordered:NO];        
        addressField.autoresizingMask = NSViewMinYMargin | NSViewWidthSizable;
        addressField.backgroundColor = [NSColor clearColor];
        addressField.font = [NSFont fontWithName:@"Helvetica" size:12];
        nameField.nextKeyView = addressField;
        addressField.nextKeyView = nameField;
        [cV addSubview:nameField];
        [cV addSubview:addressField];
        [_addressBoxView addSubview:cV];
        [nameField awakeFromNib];
        [addressField awakeFromNib];
        addressField.textColor = [NSColor colorWithCalibratedWhite:0.5 alpha:1.0];
        _addressField = addressField;
        _copyView = cV;
        nameField.stringValue = NSLocalizedString(@"Main address", @"Main address caption string for profiles");
        [[BCClient sharedClient] addObserver:self forKeyPath:@"walletHash" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
        
        // Add scroll content
        f = _profileScrollContent.frame;
        f.size.width = _profileScrollView.frame.size.width;
        f.size.height += 60;
        _profileScrollContent.frame = f;
        [_profileScrollView  setDocumentView:_profileScrollContent];

        // Now - let's set a profile view for the content

    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == [BCClient sharedClient])
    {
        if ([keyPath compare:@"walletHash"] == NSOrderedSame)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([BCClient sharedClient].walletHash)
                {
                    _addressField.stringValue = [BCClient sharedClient].walletHash;
                    _copyView.contentToCopy = [BCClient sharedClient].walletHash;
//                    [_addressField recalcForString:_addressField.stringValue];
//                    [_addressField setSelectable:YES];
                }
                
            });
        }
    }
}

- (void)controller:(HIProfileTabBarController *)controller switchedToTabIndex:(int)index
{
    // Remove what's there now
    [_profileView removeFromSuperview];
    
    switch (index) {
        case 1: // Profile view
        {
            NSRect f = _profileView.frame;
            f.origin.x = 0;
            f.origin.y = 0;
            f.size.width = _contentView.bounds.size.width;
            f.size.height = _contentView.bounds.size.height;
            _profileView.frame = f;
            [_contentView addSubview:_profileView];
        }
        break;
            
        default:
            break;
    }
}

- (IBAction) sendBitcoinsPressed:(id)sender {
    HISendBitcoinsWindowController *window = [[NSApp delegate] sendBitcoinsWindowForContact:contact];
    [window showWindow:self];
}

- (IBAction)editButtonClicked:(NSButton *)sender
{
    if (contact)
    {
        HINewContactViewController *ce = [HINewContactViewController new];
        ce.contact = contact;
        ce.title = NSLocalizedString(@"Edit contact", nil);
        [self.navigationController pushViewController:ce animated:YES];
    }
}

@end
