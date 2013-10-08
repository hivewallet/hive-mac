//
//  HINewContactViewController.m
//  Hive
//
//  Created by Bazyli Zygan on 02.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIAddress.h"
#import "HIContact.h"
#import "HINavigationController.h"
#import "HINewContactViewController.h"
#import "HIProfile.h"
#import "NSColor+Hive.h"

static const CGFloat NameFieldsGap = 10.0;
static const CGFloat NameFieldsLineSpacing = 10.0;
static const CGFloat AddressCellHeight = 60.0;

static NSString * const AddressField = @"AddressField";
static NSString * const NameField = @"NameField";
static NSString * const DeleteButton = @"DeleteButton";
static NSString * const ContentsView = @"ContentsView";
static NSString * const Separator = @"Separator";

@interface HINewContactViewController ()
{
    BOOL _nameInTwoLines;
    NSMutableArray *_placeholders;
}

@end

@implementation HINewContactViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self)
    {
        self.title = NSLocalizedString(@"New contact", @"New contact view controller title");
    }
    
    return self;
}

- (void)loadView
{
    [super loadView];

    _avatarView.layer.backgroundColor = [[NSColor whiteColor] hiNativeColor];

    // Hide some buttons if necessary

    if (!_contact || ![_contact canBeRemoved])
    {
        [self.removeContactButton setHidden:YES];

        NSRect frame = self.footerView.frame;
        frame.size.height -= 50;
        frame.origin.y += 50;
        [self.footerView setFrame:frame];
    }

    if (_contact && ![_contact canEditAddresses])
    {
        [self.addAddressButton setHidden:YES];

        for (NSView *subview in self.footerView.subviews)
        {
            NSRect frame = subview.frame;
            frame.origin.y += 39;
            [subview setFrame:frame];
        }

        NSRect frame = self.footerView.frame;
        frame.size.height -= 39;
        frame.origin.y += 39;
        [self.footerView setFrame:frame];
    }

    // Calculate content size
    NSRect frame;

    // Add content to scrollview
    frame = self.scrollContent.frame;
    frame.size.width = self.scrollView.bounds.size.width;
    self.scrollContent.frame = frame;
    [self.scrollView setDocumentView:self.scrollContent];

    // We need to set all placeholders manually
    [self.firstnameField.cell setPlaceholderString:NSLocalizedString(@"Firstname", @"Firstname field placeholder")];
    [self.lastnameField.cell setPlaceholderString:NSLocalizedString(@"Lastname", @"Lastname field placeholder")];
    [self.emailField.cell setPlaceholderString:NSLocalizedString(@"email", @"Email field placeholder")];

    // rebind nextKeyView connections
    self.lastnameField.nextKeyView = self.emailField;
    self.emailField.nextKeyView = self.firstnameField;

    _placeholders = [[NSMutableArray alloc] init];

    // Now... if we have a contact here, we need to update
    if (_contact)
    {
        if (_contact.firstname)
        {
            [self.firstnameField setValueAndRecalc:_contact.firstname];
        }

        if (_contact.lastname)
        {
            [self.lastnameField setValueAndRecalc:_contact.lastname];
        }

        if (_contact.email)
        {
            [self.emailField setValueAndRecalc:_contact.email];
        }

        for (HIAddress *address in _contact.addresses)
        {
            [self addAddressPlaceholderWithAddress:address];
        }
    }
    else
    {
        // just create a placeholder for a single address
        [self addAddressPlaceholderWithAddress:nil];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view.window makeFirstResponder:self.firstnameField];
    });

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recalculateNames:)
                                                 name:kHITextFieldContentChanged
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addAddressPlaceholderWithAddress:(HIAddress *)address
{
    NSRect frame;
    NSUInteger index = _placeholders.count;
    NSMutableDictionary *parts = [[NSMutableDictionary alloc] init];

    frame = self.walletsView.frame;
    frame.size.height += AddressCellHeight;
    frame.origin.y -= AddressCellHeight;
    self.walletsView.frame = frame;
    
    frame = self.scrollContent.frame;
    frame.size.height += AddressCellHeight;
    self.scrollContent.frame = frame;

    // If we already have fields, we need to add separator
    if (_placeholders.count > 0)
    {
        NSView *separator = [[NSView alloc] initWithFrame:
                             NSMakeRect(1, AddressCellHeight, self.walletsView.bounds.size.width - 2, 1)];

        separator.wantsLayer = YES;
        separator.layer.backgroundColor = [[NSColor colorWithCalibratedWhite:0.5 alpha:0.5] hiNativeColor];
        separator.autoresizingMask = NSViewMinYMargin | NSViewWidthSizable;

        [self.walletsView addSubview:separator];
        parts[Separator] = separator;
    }

    NSView *fieldContentView = [[NSView alloc] initWithFrame:
                                NSMakeRect(0, 0, self.walletsView.bounds.size.width - 40, AddressCellHeight)];
    fieldContentView.layer.backgroundColor = [[NSColor clearColor] hiNativeColor];
    fieldContentView.autoresizingMask = NSViewMinYMargin | NSViewWidthSizable;
    [self.walletsView addSubview:fieldContentView];
    parts[ContentsView] = fieldContentView;

    HITextField *addressField = [[HITextField alloc] initWithFrame:CGRectMake(10, 30, 100, 21)];
    addressField.autoresizingMask = NSViewMinYMargin;
    [addressField.cell setPlaceholderString:NSLocalizedString(@"Address", @"Address field placeholder")];
    addressField.font = [NSFont fontWithName:@"Helvetica" size:14];
    [fieldContentView addSubview:addressField];
    parts[AddressField] = addressField;

    HITextField *nameField = [[HITextField alloc] initWithFrame:NSMakeRect(10, 5, 100, 21)];
    nameField.autoresizingMask = NSViewMinYMargin;
    nameField.font = [NSFont fontWithName:@"Helvetica-Bold" size:14];
    [nameField.cell setPlaceholderString:NSLocalizedString(@"Label", @"Address caption field placeholder")];
    [fieldContentView addSubview:nameField];
    parts[NameField] = nameField;

    [nameField setValueAndRecalc:(address.caption ? address.caption : @"")];
    [addressField setValueAndRecalc:(address ? address.address : @"")];

    [nameField awakeFromNib];
    [addressField awakeFromNib];

    NSButton *deleteButton = [[NSButton alloc] initWithFrame:
                              NSMakeRect(self.walletsView.bounds.size.width - 40, 15, 30, 30)];
    [deleteButton setTag:index];
    [deleteButton setImage:[NSImage imageNamed:@"icon-delete"]];
    [deleteButton setTarget:self];
    [deleteButton setAction:@selector(removeAddressClicked:)];
    [deleteButton setBordered:NO];
    [deleteButton setAutoresizingMask:(NSViewMinXMargin | NSViewMinYMargin)];

    [self.walletsView addSubview:deleteButton];
    parts[DeleteButton] = deleteButton;

    if (address && ![address.contact canEditAddresses])
    {
        [nameField setEditable:NO];
        [addressField setEditable:NO];
        [deleteButton setHidden:YES];
    }

    if (index == 0)
    {
        self.lastnameField.nextKeyView = addressField;
    }
    else
    {
        [_placeholders[index - 1][NameField] setNextKeyView:addressField];
    }

    addressField.nextKeyView = nameField;
    nameField.nextKeyView = self.emailField;

    [_placeholders addObject:parts];
}

- (void)recalculateNames:(NSNotification *)notification
{
    NSRect firstFrame = self.firstnameField.frame;
    NSRect lastFrame = self.lastnameField.frame;

    CGFloat totalWidth = firstFrame.size.width + NameFieldsGap + lastFrame.size.width;
    BOOL fitsInOneLine = (totalWidth < self.view.bounds.size.width - firstFrame.origin.x);

    if (_nameInTwoLines)
    {
        if (fitsInOneLine)
        {
            // We can make them in a single line again
            firstFrame.origin.y -= NameFieldsLineSpacing;
            lastFrame.origin.y += NameFieldsLineSpacing;
            lastFrame.origin.x = firstFrame.origin.x + firstFrame.size.width + NameFieldsGap;
            self.firstnameField.frame = firstFrame;
            self.lastnameField.frame = lastFrame;
            _nameInTwoLines = NO;
        }
    }
    else
    {
        if (fitsInOneLine)
        {
            // Position firstname and lastname in a single line
            lastFrame.origin.x = firstFrame.origin.x + firstFrame.size.width + NameFieldsGap;
            self.lastnameField.frame = lastFrame;
        }
        else
        {
            // Well... we need to split them in two lines
            lastFrame.origin.x = firstFrame.origin.x;
            firstFrame.origin.y += NameFieldsLineSpacing;
            lastFrame.origin.y -= NameFieldsLineSpacing;
            _nameInTwoLines = YES;
            self.firstnameField.frame = firstFrame;
            self.lastnameField.frame = lastFrame;
        }
    }
}

- (IBAction)addAddressClicked:(NSButton *)sender
{
    [self addAddressPlaceholderWithAddress:nil];
}

- (void)removeAddressClicked:(NSButton *)button
{
    NSRect frame;
    NSUInteger index = button.tag;

    frame = self.walletsView.frame;
    frame.size.height -= AddressCellHeight;
    frame.origin.y += AddressCellHeight;
    self.walletsView.frame = frame;

    frame = self.scrollContent.frame;
    frame.size.height -= AddressCellHeight;
    self.scrollContent.frame = frame;

    [[_placeholders[index] allValues] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_placeholders removeObjectAtIndex:index];

    // For all fields below this line we need to "move them up"
    for (NSUInteger i = index; i < _placeholders.count; i++)
    {
        NSDictionary *parts = _placeholders[i];

        frame = [parts[ContentsView] frame];
        frame.origin.y += AddressCellHeight;
        [parts[ContentsView] setFrame:frame];

        frame = [parts[DeleteButton] frame];
        frame.origin.y += AddressCellHeight;
        [parts[DeleteButton] setFrame:frame];

        [parts[DeleteButton] setTag:i];
    }

    if (index == 0)
    {
        if (_placeholders.count == 0)
        {
            self.lastnameField.nextKeyView = self.emailField;
        }
        else
        {
            self.lastnameField.nextKeyView = _placeholders[0][AddressField];
        }
    }
    else
    {
        if (index < _placeholders.count)
        {
            [_placeholders[index - 1][NameField] setNextKeyView:_placeholders[index][AddressField]];
        }
        else
        {
            [_placeholders[index - 1][NameField] setNextKeyView:self.emailField];
        }
    }
}

- (IBAction)doneClicked:(NSButton *)sender
{
    NSString *firstName = self.firstnameField.enteredValue;
    NSString *lastName = self.lastnameField.enteredValue;
    NSString *email = self.emailField.enteredValue;

    if (!firstName && !lastName && (!_contact || [_contact isKindOfClass:[HIContact class]]))
    {
        NSAlert *alert = [[NSAlert alloc] init];

        alert.messageText = NSLocalizedString(@"Contact can't be saved.", @"Contact name empty alert title");
        alert.informativeText = NSLocalizedString(@"You need to give the contact a name before you can add it "
                                                  @"to the list.",
                                                  @"Contact name empty alert message");

        [alert addButtonWithTitle:NSLocalizedString(@"OK", @"OK button title")];

        [alert beginSheetModalForWindow:self.view.window
                          modalDelegate:nil
                         didEndSelector:nil
                            contextInfo:NULL];

        return;
    }

    if (!_contact)
    {
        _contact = [NSEntityDescription insertNewObjectForEntityForName:HIContactEntity
                                                 inManagedObjectContext:DBM];
    }

    // first save the basics
    _contact.firstname = (firstName.length > 0) ? firstName : nil;
    _contact.lastname = (lastName.length > 0) ? lastName : nil;
    _contact.email = (email.length > 0) ? email : nil;

    if ([_contact canEditAddresses])
    {
        // delete all old addresses first
        for (HIAddress *address in _contact.addresses)
        {
            [DBM deleteObject:address];
        }

        // add new addresses
        for (NSDictionary *parts in _placeholders)
        {
            NSString *hash = [parts[AddressField] stringValue];
            NSString *caption = [parts[NameField] stringValue];

            if (hash.length == 0)
            {
                continue;
            }

            HIAddress *address = [NSEntityDescription insertNewObjectForEntityForName:HIAddressEntity
                                                               inManagedObjectContext:DBM];

            address.caption = caption;
            address.address = hash;
            address.contact = _contact;

            [_contact addAddressesObject:address];
        }
    }

    [DBM save:NULL];

    [self.navigationController popViewController:YES];
}

- (IBAction)removeContactClicked:(NSButton *)sender
{
    NSAlert *alert = [[NSAlert alloc] init];

    NSString *info = [NSString stringWithFormat:
                      NSLocalizedString(@"Do you really want to remove %@ %@ from your contact list?",
                                        @"Remove contact alert dialog body"),
                      _contact.firstname,
                      _contact.lastname];

    [alert setMessageText:NSLocalizedString(@"Remove contact", @"Remove contact alert dialog title")];
    [alert setInformativeText:info];
    [alert addButtonWithTitle:NSLocalizedString(@"No", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
    
    NSUInteger result = [alert runModal];

    if (result == NSAlertSecondButtonReturn)
    {
        [DBM deleteObject:_contact];
        [self.navigationController popToRootViewControllerAnimated:YES];
        [DBM save:NULL];
    }

}

@end
