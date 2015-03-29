//
//  HINewContactViewController.m
//  Hive
//
//  Created by Bazyli Zygan on 02.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIAddress.h"
#import "HIBitcoinURI.h"
#import "HIBitcoinURIService.h"
#import "HICameraWindowController.h"
#import "HIContact.h"
#import "HIDatabaseManager.h"
#import "HINavigationController.h"
#import "HINewContactViewController.h"
#import "HIProfile.h"
#import "NSAlert+Hive.h"
#import "NSColor+Hive.h"
#import "NSURL+Gravatar.h"

#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory+OSX.h>

static const CGFloat NameFieldsGap = 10.0;
static const CGFloat NameFieldsLineSpacing = 10.0;
static const CGFloat AddressCellHeight = 60.0;

static NSString * const AddressField = @"AddressField";
static NSString * const NameField = @"NameField";
static NSString * const DeleteButton = @"DeleteButton";
static NSString * const ContentsView = @"ContentsView";
static NSString * const Separator = @"Separator";

@interface HINewContactViewController () <HICameraWindowControllerDelegate> {
    BOOL _nameInTwoLines;
    BOOL _avatarChanged;
    BOOL _edited;
    NSMutableArray *_placeholders;
}

@property (nonatomic, weak) IBOutlet HITextField *firstnameField;
@property (nonatomic, weak) IBOutlet HITextField *lastnameField;
@property (nonatomic, weak) IBOutlet HITextField *emailField;
@property (nonatomic, weak) IBOutlet HIBox *walletsView;
@property (nonatomic, weak) IBOutlet NSScrollView *scrollView;
@property (nonatomic, weak) IBOutlet NSView *footerView;
@property (nonatomic, weak) IBOutlet NSButton *addAddressButton;
@property (nonatomic, weak) IBOutlet NSButton *scanQRCodeButton;
@property (nonatomic, weak) IBOutlet NSButton *removeContactButton;
@property (nonatomic, weak) IBOutlet NSTextField *editAvatarLabel;
@property (nonatomic, weak) IBOutlet NSImageView *avatarView;

// top-level objects
@property (nonatomic, strong) IBOutlet NSView *scrollContent;

- (IBAction)cancelClicked:(NSButton *)sender;
- (IBAction)doneClicked:(NSButton *)sender;
- (IBAction)removeContactClicked:(NSButton *)sender;
- (IBAction)addAddressClicked:(NSButton *)sender;
- (IBAction)avatarChanged:(id)sender;

@end

@implementation HINewContactViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        self.title = NSLocalizedString(@"New contact", @"New contact view controller title");
    }
    
    return self;
}

- (void)loadView {
    [super loadView];

    [self setUpQrCodeButton];
    _avatarView.layer.backgroundColor = [[NSColor whiteColor] CGColor];

    // Hide some buttons if necessary

    if (!_contact || ![_contact canBeRemoved]) {
        [self.removeContactButton setHidden:YES];

        NSRect frame = self.footerView.frame;
        frame.size.height -= 50;
        frame.origin.y += 50;
        [self.footerView setFrame:frame];
    }

    if (_contact && ![_contact canEditAddresses]) {
        [self.addAddressButton setHidden:YES];
        [self.scanQRCodeButton setHidden:YES];

        for (NSView *subview in self.footerView.subviews) {
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

    [self trackChangesIn:self.firstnameField];
    [self trackChangesIn:self.lastnameField];
    [self trackChangesIn:self.emailField];

    // rebind nextKeyView connections
    self.lastnameField.nextKeyView = self.emailField;
    self.emailField.nextKeyView = self.firstnameField;

    // resize email field label
    NSView *label = self.emailField.superview.subviews.firstObject;
    NSRect labelFrame = label.frame;
    labelFrame.size.width = label.intrinsicContentSize.width;
    label.frame = labelFrame;

    NSRect emailFrame = self.emailField.frame;
    emailFrame.origin.x = labelFrame.origin.x + labelFrame.size.width + 10.0;
    self.emailField.frame = emailFrame;

    // quick fix for edit label in some languages (e.g. Greek, Hungarian)
    if (self.editAvatarLabel.intrinsicContentSize.width > self.editAvatarLabel.frame.size.width) {
        self.editAvatarLabel.font = [NSFont fontWithName:self.editAvatarLabel.font.fontName size:10.0];
    }

    _placeholders = [[NSMutableArray alloc] init];

    // Now... if we have a contact here, we need to update
    if (_contact) {
        if (_contact.firstname) {
            [self.firstnameField setValueAndRecalc:_contact.firstname];
        }

        if (_contact.lastname) {
            [self.lastnameField setValueAndRecalc:_contact.lastname];
        }

        if (_contact.email) {
            [self.emailField setValueAndRecalc:_contact.email];
        }

        if (_contact.avatarImage) {
            self.avatarView.image = _contact.avatarImage;
        }

        for (HIAddress *address in _contact.addresses) {
            [self addAddressPlaceholderWithAddress:address];
        }
    } else {
        // just create a placeholder for a single address
        [self addAddressPlaceholderWithAddress:nil];

        // make sure placeholders are fully visible regardless of locale
        [self.firstnameField recalcForString:[self.firstnameField.cell placeholderString]];
        [self.lastnameField recalcForString:[self.lastnameField.cell placeholderString]];
        [self.emailField recalcForString:[self.emailField.cell placeholderString]];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view.window makeFirstResponder:self.firstnameField];
    });

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recalculateNames:)
                                                 name:kHITextFieldContentChanged
                                               object:nil];
}

- (void)setUpQrCodeButton {
    NIKFontAwesomeIconFactory *iconFactory = [NIKFontAwesomeIconFactory new];
    iconFactory.edgeInsets = NSEdgeInsetsMake(4, 0, 0, 0);
    iconFactory.size = 28;
    self.scanQRCodeButton.image = [iconFactory createImageForIcon:NIKFontAwesomeIconQrcode];
}

- (void)trackChangesIn:(NSTextField *)field {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldChanged:)
                                                 name:NSControlTextDidChangeNotification
                                               object:field];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addAddressPlaceholderWithAddress:(HIAddress *)address {
    [self addAddressPlaceholderWithHash:address.address
                                   name:address.caption
                               editable:(!address || [address.contact canEditAddresses])];
}

- (void)addAddressPlaceholderWithHash:(NSString *)address name:(NSString *)name editable:(BOOL)editable {
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
    if (_placeholders.count > 0) {
        NSView *separator = [[NSView alloc] initWithFrame:
                             NSMakeRect(1, AddressCellHeight, self.walletsView.bounds.size.width - 2, 1)];

        separator.wantsLayer = YES;
        separator.layer.backgroundColor = [[NSColor colorWithCalibratedWhite:0.5 alpha:0.5] CGColor];
        separator.autoresizingMask = NSViewMinYMargin | NSViewWidthSizable;

        [self.walletsView addSubview:separator];
        parts[Separator] = separator;
    }

    NSView *fieldContentView = [[NSView alloc] initWithFrame:
                                NSMakeRect(0, 0, self.walletsView.bounds.size.width - 40, AddressCellHeight)];
    fieldContentView.layer.backgroundColor = [[NSColor clearColor] CGColor];
    fieldContentView.autoresizingMask = NSViewMinYMargin | NSViewWidthSizable;
    [self.walletsView addSubview:fieldContentView];
    parts[ContentsView] = fieldContentView;

    HITextField *addressField = [[HITextField alloc] initWithFrame:CGRectMake(10, 30, 100, 21)];
    addressField.autoresizingMask = NSViewMinYMargin;
    [addressField.cell setPlaceholderString:NSLocalizedString(@"Address", @"Address field placeholder")];
    addressField.font = [NSFont systemFontOfSize:13.0];
    [fieldContentView addSubview:addressField];
    parts[AddressField] = addressField;

    HITextField *nameField = [[HITextField alloc] initWithFrame:NSMakeRect(10, 5, 100, 21)];
    nameField.autoresizingMask = NSViewMinYMargin;
    nameField.font = [NSFont boldSystemFontOfSize:13.0];
    [nameField.cell setPlaceholderString:NSLocalizedString(@"Label", @"Address caption field placeholder")];
    [fieldContentView addSubview:nameField];
    parts[NameField] = nameField;

    [nameField setValueAndRecalc:(name ?: @"")];
    [addressField setValueAndRecalc:(address ?: @"")];

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

    if (!editable) {
        [nameField setEditable:NO];
        [addressField setEditable:NO];
        [deleteButton setHidden:YES];
    }

    if (index == 0) {
        self.lastnameField.nextKeyView = addressField;
    } else {
        [_placeholders[index - 1][NameField] setNextKeyView:addressField];
    }

    addressField.nextKeyView = nameField;
    nameField.nextKeyView = self.emailField;

    [self trackChangesIn:addressField];
    [self trackChangesIn:nameField];

    [_placeholders addObject:parts];

    [self.view.window makeFirstResponder:addressField];
}

- (void)recalculateNames:(NSNotification *)notification {
    NSRect firstFrame = self.firstnameField.frame;
    NSRect lastFrame = self.lastnameField.frame;

    CGFloat totalWidth = firstFrame.size.width + NameFieldsGap + lastFrame.size.width;
    BOOL fitsInOneLine = (totalWidth < self.view.bounds.size.width - firstFrame.origin.x);

    if (_nameInTwoLines) {
        if (fitsInOneLine) {
            // We can make them in a single line again
            firstFrame.origin.y -= NameFieldsLineSpacing;
            lastFrame.origin.y += NameFieldsLineSpacing;
            lastFrame.origin.x = firstFrame.origin.x + firstFrame.size.width + NameFieldsGap;
            self.firstnameField.frame = firstFrame;
            self.lastnameField.frame = lastFrame;
            _nameInTwoLines = NO;
        }
    } else {
        if (fitsInOneLine) {
            // Position firstname and lastname in a single line
            lastFrame.origin.x = firstFrame.origin.x + firstFrame.size.width + NameFieldsGap;
            self.lastnameField.frame = lastFrame;
        } else {
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

- (IBAction)addAddressClicked:(NSButton *)sender {
    _edited = YES;
    [self addAddressPlaceholderWithAddress:nil];
}

- (void)removeAddressClicked:(NSButton *)button {
    NSUInteger index = button.tag;
    [self removeAddressPlaceholderAtIndex:index];
}

- (void)removeAddressPlaceholderAtIndex:(NSUInteger)index {
    _edited = YES;

    NSRect frame;

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
    for (NSUInteger i = index; i < _placeholders.count; i++) {
        NSDictionary *parts = _placeholders[i];

        frame = [parts[ContentsView] frame];
        frame.origin.y += AddressCellHeight;
        [parts[ContentsView] setFrame:frame];

        frame = [parts[DeleteButton] frame];
        frame.origin.y += AddressCellHeight;
        [parts[DeleteButton] setFrame:frame];

        [parts[DeleteButton] setTag:i];
    }

    if (index == 0) {
        if (_placeholders.count == 0) {
            self.lastnameField.nextKeyView = self.emailField;
        } else {
            self.lastnameField.nextKeyView = _placeholders[0][AddressField];
        }
    } else {
        if (index < _placeholders.count) {
            [_placeholders[index - 1][NameField] setNextKeyView:_placeholders[index][AddressField]];
        } else {
            [_placeholders[index - 1][NameField] setNextKeyView:self.emailField];
        }
    }
}

- (void)removeLastPlaceholderIfEmpty {
    NSDictionary *lastPlaceholder = _placeholders.lastObject;

    if (lastPlaceholder && [[lastPlaceholder[NameField] stringValue] isEqual:@""]
                        && [[lastPlaceholder[AddressField] stringValue] isEqual:@""]) {
        [self removeAddressPlaceholderAtIndex:(_placeholders.count - 1)];
    }
}

- (void)textFieldChanged:(NSNotification *)notification {
    _edited = YES;
    if (!_contact.avatar.length && !_avatarChanged && self.emailField.enteredValue.length > 0) {
        [self fetchGravatarForEmailAddress:self.emailField.enteredValue];
    }
}

- (void)avatarChanged:(id)sender {
    _edited = YES;
    _avatarChanged = YES;
}

- (IBAction)cancelClicked:(id)sender {
    [self requestPopFromStackWithAction:^{
        [self.navigationController popViewController:YES];
    }];
}

- (IBAction)doneClicked:(NSButton *)sender {
    NSString *firstName = self.firstnameField.enteredValue;
    NSString *lastName = self.lastnameField.enteredValue;
    NSString *email = self.emailField.enteredValue;

    if (!firstName && !lastName && (!_contact || [_contact isKindOfClass:[HIContact class]])) {
        NSAlert *alert = [NSAlert hiOKAlertWithTitle:NSLocalizedString(@"Contact can't be saved.",
                                                                       @"Contact name empty alert title")
                                             message:NSLocalizedString(@"You need to give the contact a name "
                                                                       @"before you can add it to the list.",
                                                                       @"Contact name empty alert message")];
        [alert beginSheetModalForWindow:self.view.window
                          modalDelegate:nil
                         didEndSelector:nil
                            contextInfo:NULL];

        return;
    }

    if (!_contact) {
        _contact = [NSEntityDescription insertNewObjectForEntityForName:HIContactEntity
                                                 inManagedObjectContext:DBM];
    }

    // first save the basics
    _contact.firstname = (firstName.length > 0) ? firstName : nil;
    _contact.lastname = (lastName.length > 0) ? lastName : nil;
    _contact.email = (email.length > 0) ? email : nil;

    if (_avatarChanged) {
        _contact.avatar = [self.avatarView.image TIFFRepresentation];
    }

    if ([_contact canEditAddresses]) {
        // delete all old addresses first
        for (HIAddress *address in _contact.addresses) {
            [DBM deleteObject:address];
        }

        // add new addresses
        for (NSDictionary *parts in _placeholders) {
            NSString *hash = [parts[AddressField] stringValue];
            NSString *caption = [parts[NameField] stringValue];

            if (hash.length == 0) {
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

- (IBAction)removeContactClicked:(NSButton *)sender {
    NSAlert *alert = [[NSAlert alloc] init];

    NSString *title = [NSString stringWithFormat:
                       NSLocalizedString(@"Do you really want to remove %@ from your contact list?",
                                         @"Remove contact alert dialog title"),
                       _contact.name];

    [alert setMessageText:title];
    [alert setInformativeText:NSLocalizedString(@"You won't be able to undo this operation.",
                                                @"Remove contact alert dialog body")];

    [alert addButtonWithTitle:NSLocalizedString(@"Remove", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];

    [alert beginSheetModalForWindow:self.view.window
                      modalDelegate:self
                     didEndSelector:@selector(removeContactAlertDidEnd:result:context:)
                        contextInfo:NULL];
}

- (void)removeContactAlertDidEnd:(NSAlert *)alert result:(NSInteger)result context:(void *)context {
    if (result == NSAlertFirstButtonReturn) {
        [DBM deleteObject:_contact];
        [self.navigationController popToRootViewControllerAnimated:YES];
        [DBM save:NULL];
    }
}

- (void)requestPopFromStackWithAction:(void (^)())action {
    if (_edited) {
        NSAlert *alert = [[NSAlert alloc] init];

        [alert setMessageText:NSLocalizedString(@"Are you sure you want to leave this page?",
                                                @"Cancel editing alert title")];
        [alert setInformativeText:NSLocalizedString(@"Your changes won't be saved.",
                                                    @"Cancel editing alert message")];

        [alert addButtonWithTitle:NSLocalizedString(@"Discard Changes",
                                                    @"Confirm leaving a form without saving data")];
        [alert addButtonWithTitle:NSLocalizedString(@"Keep Editing",
                                                    @"Don't leave a form without saving data")];

        [alert beginSheetModalForWindow:self.view.window
                          modalDelegate:self
                         didEndSelector:@selector(discardChangesAlertDidEnd:result:context:)
                            contextInfo:(void *)CFBridgingRetain(action)];
    } else {
        [self cleanUpWithAction:action];
    }
}

- (void)discardChangesAlertDidEnd:(NSAlert *)alert result:(NSInteger)result context:(void *)context {
    void (^action)() = (void (^)()) CFBridgingRelease(context);

    if (result == NSAlertFirstButtonReturn) {
        [self cleanUpWithAction:action];
    }
}

- (void)cleanUpWithAction:(void (^)())action {
    [self cleanUpCameraWindow];
    action();
}

#pragma mark - QR code

- (IBAction)scanQRCodeButtonPressed:(NSButton *)sender {
    [HICameraWindowController sharedCameraWindowController].delegate = self;
    [[HICameraWindowController sharedCameraWindowController] showWindow:nil];
}

- (void)cleanUpCameraWindow {
    if ([HICameraWindowController sharedCameraWindowController].delegate == self) {
        [HICameraWindowController sharedCameraWindowController].delegate = nil;
        [[HICameraWindowController sharedCameraWindowController].window performClose:nil];
    }
}

#pragma mark - HICameraWindowControllerDelegate

- (BOOL)cameraWindowController:(HICameraWindowController *)cameraWindowController
              didScanQRCodeURI:(NSString *)QRCodeURI {

    HIBitcoinURI *uri = [[HIBitcoinURI alloc] initWithURIString:QRCodeURI];

    if (uri.valid) {
        _edited = YES;
        [self removeLastPlaceholderIfEmpty];
        [self addAddressPlaceholderWithHash:uri.address name:nil editable:YES];
        [self.view.window makeFirstResponder:_placeholders.lastObject[NameField]];
    } else {
        [[HIBitcoinURIService sharedService] showQRCodeErrorForURI:QRCodeURI];
    }

    return uri.valid;
}

#pragma mark - gravatar

- (void)fetchGravatarForEmailAddress:(NSString *)email {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *url = [NSURL URLWithGravatarEmail:email size:512];
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
        if (image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // Make sure the user didn't select one while we waited.
                if (!_avatarChanged) {
                    self.avatarView.image = image;
                    _avatarChanged = YES;
                }
            });
        }
    });
}

@end
