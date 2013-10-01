//
//  HINewContactViewController.m
//  Hive
//
//  Created by Bazyli Zygan on 02.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HINewContactViewController.h"
#import "HINavigationController.h"
#import "HIContact.h"
#import "HIAddress.h"
#import "NSColor+NativeColor.h"

@interface HINewContactViewController ()
{
    BOOL _nameInTwoLines;
    NSMutableArray *_walletNameFields;
    NSMutableArray *_walletAddressFields;
    NSMutableArray *_walletRemovalButtons;
    NSMutableArray *_fieldContents;
    NSMutableArray *_separators;
}

- (void)deleteButtonTapped:(NSButton *)button;
@end

@implementation HINewContactViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"New contact", @"New contact view controller title");
    }
    
    return self;
}

- (void)addAddressPlaceholderAnimated:(BOOL)animated
{
    NSRect f = _walletsView.frame;
    f.size.height += 60;
    f.origin.y -= 60;
    _walletsView.frame = f;
    
    f = _scrollContent.frame;
    f.size.height += 60;
    _scrollContent.frame = f;
    
    // If we already have fields, we need to add separator
    if (_walletAddressFields.count > 0)
    {
        NSView *separator = [[NSView alloc] initWithFrame:NSMakeRect(1, 60, _walletsView.bounds.size.width-2, 1)];
        
        separator.wantsLayer = YES;
        separator.layer.backgroundColor = [[NSColor colorWithCalibratedWhite:0.5 alpha:0.5] NativeColor];
        separator.autoresizingMask = NSViewMinYMargin | NSViewWidthSizable;
        [_walletsView addSubview:separator];
        [_separators addObject:separator];
        
    }
    
    NSView *fieldContentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, _walletsView.bounds.size.width - 40, 60)];
    fieldContentView.layer.backgroundColor = [[NSColor clearColor] NativeColor];
    fieldContentView.autoresizingMask = NSViewMinYMargin | NSViewWidthSizable;
    [_walletsView addSubview:fieldContentView];
    [_fieldContents addObject:fieldContentView];
    
    HITextField *nameField = [[HITextField alloc] initWithFrame:CGRectMake(10, 30, 100, 21)];
    nameField.autoresizingMask = NSViewMinYMargin;
    nameField.font = [NSFont fontWithName:@"Helvetica-Bold" size:14];
    [nameField.cell setPlaceholderString:NSLocalizedString(@"Address caption", @"Address caption field placeholder")];
    
    HITextField *addressField = [[HITextField alloc] initWithFrame:CGRectMake(10, 5, 100, 21)];
    addressField.autoresizingMask = NSViewMinYMargin;
    [addressField.cell setPlaceholderString:NSLocalizedString(@"Address", @"Address field placeholder")];
    addressField.font = [NSFont fontWithName:@"Helvetica" size:14];
    nameField.nextKeyView = addressField;
    addressField.nextKeyView = nameField;
    [fieldContentView addSubview:nameField];
    [fieldContentView addSubview:addressField];
    [nameField recalcForString:@""];
    [addressField recalcForString:@""];
    [nameField awakeFromNib];
    [addressField awakeFromNib];
    
    NSButton *delBtn = [[NSButton alloc] initWithFrame:NSMakeRect(_walletsView.bounds.size.width - 40, 15, 30, 30)];
    delBtn.tag = _walletNameFields.count;
    [delBtn setImage:[NSImage imageNamed:@"icon-delete"]];
    [delBtn setTarget:self];
    [delBtn setAction:@selector(deleteButtonTapped:)];
    [delBtn setBordered:NO];
    delBtn.autoresizingMask = NSViewMinXMargin | NSViewMinYMargin;
    [_walletsView addSubview:delBtn];
    [_walletRemovalButtons addObject:delBtn];
    [_walletNameFields addObject:nameField];
    [_walletAddressFields addObject:addressField];
}

- (void)deleteButtonTapped:(NSButton *)button
{
    NSUInteger idx = button.tag;
    
    NSRect f = _walletsView.frame;
    f.size.height -= 60;
    f.origin.y += 60;
    _walletsView.frame = f;
    
    f = _scrollContent.frame;
    f.size.height -= 60;
    _scrollContent.frame = f;
    
    [_walletNameFields[idx] removeFromSuperview];
    [_walletNameFields removeObjectAtIndex:idx];
    [_walletAddressFields[idx] removeFromSuperview];
    [_walletAddressFields removeObjectAtIndex:idx];
    [_walletRemovalButtons[idx] removeFromSuperview];
    [_walletRemovalButtons removeObjectAtIndex:idx];
    [_fieldContents[idx] removeFromSuperview];
    [_fieldContents removeObjectAtIndex:idx];
    
    // For all fields below this line we need to "move them up"
    for (int i = (int)idx ; i < _walletNameFields.count; i++)
    {
        NSRect f = [_fieldContents[i] frame];
        f.origin.y += 60;
        [_fieldContents[i] setFrame:f];

        f = [_walletRemovalButtons[i] frame];
        f.origin.y += 60;
        [_walletRemovalButtons[i] setFrame:f];
        [_walletRemovalButtons[i] setTag:i];
    }
    
    if (_separators.count > 0)
    {
        [_separators[_separators.count-1] removeFromSuperview];
        [_separators removeObjectAtIndex:_separators.count-1];
    }
    

}

- (void)loadView
{
    [super loadView];
    _avatarView.layer.backgroundColor = [[NSColor whiteColor] NativeColor];
//    _addWalletBtn.layer.cornerRadius = 4.0;
    
    // Hide remove button if necessary
    if (!_contact)
        [_removeContactBtn setHidden:YES];
    
    // Calculate content size
    
    // Add content to scrollview
    NSRect f = _scrollContent.frame;
    f.size.width = _scrollView.bounds.size.width;
    _scrollContent.frame = f;
    [_scrollView setDocumentView:_scrollContent];
    
    // We need to set all placeholders manually
    [_firstnameField.cell setPlaceholderString:NSLocalizedString(@"Firstname", @"Firstname field placeholder")];
    [_lastnameField.cell setPlaceholderString:NSLocalizedString(@"Lastname", @"Lastname field placeholder")];
    [_emailField.cell setPlaceholderString:NSLocalizedString(@"email", @"Email field placeholder")];
//    [_walletAddressField.cell setPlaceholderString:NSLocalizedString(@"Address", @"Address field placeholder")];
//    [_walletNameField.cell setPlaceholderString:NSLocalizedString(@"Address caption", @"Address caption field placeholder")];
    
    _walletAddressFields = [NSMutableArray new];
    _walletNameFields = [NSMutableArray new];
    _walletRemovalButtons = [NSMutableArray new];
    _fieldContents = [NSMutableArray new];
    _separators = [NSMutableArray new];
    
    [self addAddressPlaceholderAnimated:NO];

    // Now... if we have a contact here, we need to update
    if (_contact)
    {
        if (_contact.firstname)
        {
            _firstnameField.stringValue = _contact.firstname;
            [_firstnameField recalcForString:_contact.firstname];
        }
        
        if (_contact.lastname)
        {
            _lastnameField.stringValue = _contact.lastname;
            [_lastnameField recalcForString:_contact.lastname];
        }
        
        if (_contact.email)
        {
            _emailField.stringValue = _contact.email;
            [_emailField recalcForString:_contact.email];
        }
        
        // Create place for addresses
        for (int i = 1; i < _contact.addresses.count; i++)
            [self addAddressPlaceholderAnimated:NO];
        
        // Now copy all the stuff from addresses to save
        int idx = 0;
        for (HIAddress *addr in _contact.addresses)
        {
            HITextField *nF = _walletNameFields[idx];
            HITextField *aF = _walletAddressFields[idx];
            
            if (addr.caption)
            {
                nF.stringValue = addr.caption;
                [nF recalcForString:addr.caption];
            }
            
            aF.stringValue = addr.address;
            [aF recalcForString:addr.address];
            idx++;
        }
        
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view.window makeFirstResponder:_firstnameField];
        [self.view.window makeFirstResponder:_firstnameField];           
    });

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recalculateNames:) name:kHITextFieldContentChanged object:nil];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)recalculateNames:(NSNotification *)not;
{
    NSRect r1, r2;
    r1 = _firstnameField.frame;
    r2 = _lastnameField.frame;
    if (_nameInTwoLines)
    {
        // Check if we can fit both in one line
        if (r1.size.width + r2.size.width + 10 < self.view.bounds.size.width - r1.origin.x)
        {
            // We can make them in a single line again
            r1.origin.y -= 10;
            r2.origin.y += 10;
            r2.origin.x = r1.origin.x + r1.size.width + 10;
            _firstnameField.frame = r1;
            _lastnameField.frame = r2;
            _nameInTwoLines = NO;
        }
    }
    else
    {
        // Check if those will fit a single line
        if (r1.size.width + r2.size.width + 10 < self.view.bounds.size.width - r1.origin.x)
        {
            // Position firstname and lastname in a single line
            r2.origin.x = r1.origin.x + r1.size.width + 10;
            _lastnameField.frame = r2;
        }
        else
        {
            // Well... we need to split them in two lines
            r2.origin.x = r1.origin.x;
            r1.origin.y += 10;
            r2.origin.y -= 10;
            _nameInTwoLines = YES;
            _firstnameField.frame = r1;
            _lastnameField.frame = r2;
        }
    }
}


- (IBAction)doneClicked:(NSButton *)sender
{
    if ((_firstnameField.stringValue.length > 0 && !_firstnameField.isEmpty) ||
        (_lastnameField.stringValue.length > 0 && !_lastnameField.isEmpty))
    {
        if (!_contact)
        {
            // We should create a contact now
            HIContact * c = [NSEntityDescription
                            insertNewObjectForEntityForName:HIContactEntity
                            inManagedObjectContext:DBM];
            
            if (_firstnameField.stringValue.length > 0)
                c.firstname = _firstnameField.stringValue;
            
            if (_lastnameField.stringValue.length > 0)
                c.lastname = _lastnameField.stringValue;
            
            if (_emailField.stringValue.length > 0)
                c.email = _emailField.stringValue;
            
            for (int i = 0; i < _walletAddressFields.count; i++)
            {
                NSString *address = [_walletAddressFields[i] stringValue];
                NSString *caption = [_walletNameFields[i] stringValue];
                if (address.length == 0)
                    continue;
                
                HIAddress * a = [NSEntityDescription
                                 insertNewObjectForEntityForName:HIAddressEntity
                                 inManagedObjectContext:DBM];

                a.caption = caption;
                a.address = address;

                [c addAddressesObject:a];
                a.contact = c;
                
            }
        }
        else
        {
            // First save the basics
            if (_firstnameField.stringValue.length > 0)
                _contact.firstname = _firstnameField.stringValue;
            else
                _contact.firstname = nil;
            
            if (_lastnameField.stringValue.length > 0)
                _contact.lastname = _lastnameField.stringValue;
            else
                _contact.lastname = nil;
            
            if (_emailField.stringValue.length > 0)
                _contact.email = _emailField.stringValue;
            else
                _contact.email = nil;
            
            // Now - delete all the addresses first
            for (HIAddress *addr in _contact.addresses)
                [DBM deleteObject:addr];
            
            // And add them anew
            for (int i = 0; i < _walletAddressFields.count; i++)
            {
                NSString *address = [_walletAddressFields[i] stringValue];
                NSString *caption = [_walletNameFields[i] stringValue];
                if (address.length == 0)
                    continue;
                
                HIAddress * a = [NSEntityDescription
                                 insertNewObjectForEntityForName:HIAddressEntity
                                 inManagedObjectContext:DBM];
                
                a.caption = caption;
                a.address = address;
                
                [_contact addAddressesObject:a];
                a.contact = _contact;
                
            }
        }
        NSError *err = nil;
        [DBM save:&err];
    }
    
    [self.navigationController popViewController:YES];
}

- (IBAction)removeClicked:(NSButton *)sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"Remove contact", @"Remove contact alert dialog title")];
    [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Do you really want to remove %@ %@ from your contact list?", @"Remove contact alert dialog body"), _contact.firstname, _contact.lastname]];
    [alert addButtonWithTitle:NSLocalizedString(@"No", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
    
    NSUInteger retVal = [alert runModal];
    if (retVal == 1001)
    {
        // Time to remove!
        [DBM deleteObject:_contact];
        [self.navigationController popToRootViewControllerAnimated:YES];
        [DBM save:NULL];
    }

}

- (IBAction)addAddressClicked:(NSButton *)sender
{
    [self addAddressPlaceholderAnimated:YES];
}
@end
