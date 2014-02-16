#import "HIAddressesBox.h"

#import "HIBox.h"
#import "HIAddress.h"
#import "HIBarcodeWindowController.h"
#import "HICopyView.h"
#import "BCClient.h"
#import "NSColor+Hive.h"

#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory+OSX.h>

static const NSInteger AddressFieldTag = 2;
static const double BARCODE_ZOOM_SIZE = 400;

static NSString *const KEY_WALLET_HASH = @"walletHash";

@interface HIAddressesBox ()

@property (nonatomic, strong, readonly) HIBox *box;
@property (nonatomic, copy, readonly) NSMutableArray *contentViews;
@property (nonatomic, strong, readonly) NSButton *barcodeButton;
@property (nonatomic, strong) NSTrackingArea *trackingArea;
@property (nonatomic, strong) HIBarcodeWindowController *barcodeWindowController;

@end


@implementation HIAddressesBox

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _box = [[HIBox alloc] initWithFrame:self.bounds];
        _box.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_box];
        [self addConstraints:@[
            INSET_TOP(_box, 0.0),
            INSET_LEFT(_box, 0.0),
            INSET_BOTTOM(_box, 0.0),
            INSET_RIGHT(_box, 0.0),
        ]];
        _contentViews = [NSMutableArray new];
        [self updateAddresses];
        [self setUpBarcodeButton];
    }

    return self;
}

- (void)setUpBarcodeButton {
    _barcodeButton = [NSButton new];
    _barcodeButton.bezelStyle = NSSmallSquareBezelStyle;
    _barcodeButton.translatesAutoresizingMaskIntoConstraints = NO;
    NIKFontAwesomeIconFactory *iconFactory = [NIKFontAwesomeIconFactory new];
    iconFactory.size = 14;
    _barcodeButton.image = [iconFactory createImageForIcon:NIKFontAwesomeIconQrcode];
    _barcodeButton.target = self;
    _barcodeButton.action = @selector(showBarcodeWindow:);

    [self addSubview:_barcodeButton];
    [_barcodeButton addConstraint:PIN_WIDTH(_barcodeButton, 21)];
    [_barcodeButton addConstraint:PIN_HEIGHT(_barcodeButton, 21)];
    [self addConstraint:INSET_BOTTOM(_barcodeButton, 10)];
    [self addConstraint:INSET_RIGHT(_barcodeButton, 10)];
}

- (void)dealloc {
    [self removeTrackingArea:self.trackingArea];
    if (_observingWallet) {
        [[BCClient sharedClient] removeObserver:self forKeyPath:KEY_WALLET_HASH];
    }
}

- (void)setAddresses:(NSArray *)addresses {
    _addresses = [addresses copy];
    [self updateAddresses];
    self.observingWallet = NO;
}

- (void)updateAddresses {

    // clean up the box
    [self.contentViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.contentViews removeAllObjects];

    // fill it with new address views
    NSInteger index = 0;

    for (HIAddress *address in self.addresses) {
        if (index > 0) {
            [self.contentViews addObject:[self addressSeparatorViewAtIndex:index]];
        }

        [self.contentViews addObject:[self copyViewAtIndex:index forAddress:address]];

        index++;
    }

    for (NSView *view in self.contentViews) {
        [self addSubview:view positioned:NSWindowBelow relativeTo:self.barcodeButton];
    }

    [self invalidateIntrinsicContentSize];
}

- (NSView *)addressSeparatorViewAtIndex:(NSInteger)index {
    NSRect frame = NSMakeRect(1, 60 * index, self.bounds.size.width - 2, 1);
    NSView *separator = [[NSView alloc] initWithFrame:frame];

    separator.wantsLayer = YES;
    separator.layer.backgroundColor = [[NSColor colorWithCalibratedWhite:0.5 alpha:0.5] hiNativeColor];
    separator.autoresizingMask = NSViewMinYMargin | NSViewWidthSizable;

    return separator;
}

- (HICopyView *)copyViewAtIndex:(NSInteger)index forAddress:(HIAddress *)address {
    // build the copy view
    NSRect copyViewFrame = NSMakeRect(0, index * 60, self.bounds.size.width, 60);
    HICopyView *copyView = [[HICopyView alloc] initWithFrame:copyViewFrame];
    copyView.autoresizingMask = NSViewWidthSizable;
    copyView.contentToCopy = address.address;

    // build the name subview
    NSRect nameFieldFrame = NSMakeRect(10, 30, self.bounds.size.width - 20, 21);
    NSTextField *nameField = [[NSTextField alloc] initWithFrame:nameFieldFrame];
    [nameField.cell setLineBreakMode:NSLineBreakByTruncatingTail];
    [nameField setAutoresizingMask:(NSViewMinYMargin | NSViewWidthSizable)];
    [nameField setFont:[NSFont fontWithName:@"Helvetica-Bold" size:14]];
    [nameField setEditable:NO];
    [nameField setSelectable:NO];
    [nameField setBordered:NO];
    [nameField setBackgroundColor:[NSColor clearColor]];

    if (address.caption) {
        nameField.stringValue = address.caption;
    } else {
        nameField.stringValue = NSLocalizedString(@"Main address", @"Main address caption string for profiles");
    }

    // build the address subview
    NSRect addressFieldFrame = NSMakeRect(10, 7, self.bounds.size.width - 20, 21);
    NSTextField *addressField = [[NSTextField alloc] initWithFrame:addressFieldFrame];
    [addressField.cell setLineBreakMode:NSLineBreakByTruncatingMiddle];
    [addressField.cell setSelectable:YES];
    [addressField setEditable:NO];
    [addressField setSelectable:NO];
    [addressField setBordered:NO];
    [addressField setBackgroundColor:[NSColor clearColor]];
    [addressField setAutoresizingMask:(NSViewMinYMargin | NSViewWidthSizable)];
    [addressField setFont:[NSFont fontWithName:@"Helvetica" size:12]];
    [addressField setTextColor:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0]];
    [addressField setTag:AddressFieldTag];

    if (address.address) {
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

- (NSSize)intrinsicContentSize {
    return CGSizeMake(NSViewNoInstrinsicMetric, 60 * self.addresses.count);
}

#pragma mark - KVO

- (void)setObservingWallet:(BOOL)observingWallet {
    if (_observingWallet && !observingWallet) {
        [[BCClient sharedClient] removeObserver:self forKeyPath:KEY_WALLET_HASH];
    }
    if (!_observingWallet && observingWallet) {
        [[BCClient sharedClient] addObserver:self
                                  forKeyPath:KEY_WALLET_HASH
                                     options:NSKeyValueObservingOptionInitial
                                     context:NULL];
    }
    _observingWallet = observingWallet;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (object == [BCClient sharedClient] && [keyPath isEqual:@"walletHash"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *walletHash = [[BCClient sharedClient] walletHash];

            if (walletHash) {
                HICopyView *userAddressView = self.contentViews[0];
                [userAddressView setContentToCopy:walletHash];
                [[userAddressView viewWithTag:AddressFieldTag] setStringValue:walletHash];
            }
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - mouse handling

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self removeTrackingArea:self.trackingArea];

    self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                     options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                                       owner:self
                                                    userInfo:nil];
    [self addTrackingArea:self.trackingArea];

    NSPoint mouseLocation = [self.window mouseLocationOutsideOfEventStream];
    self.mouseInside = NSPointInRect([self convertPoint:mouseLocation fromView:nil], self.bounds);

    [super updateTrackingAreas];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    [super mouseEntered:theEvent];
    self.mouseInside = YES;
}

- (void)mouseExited:(NSEvent *)theEvent {
    self.mouseInside = NO;
    [super mouseExited:theEvent];
}

- (void)setMouseInside:(BOOL)mouseInside {
    self.barcodeButton.hidden = !self.showsBarcode || !mouseInside;
}

#pragma mark - barcode window

- (void)showBarcodeWindow:(NSButton *)sender {
    self.barcodeWindowController = [HIBarcodeWindowController new];
    self.barcodeWindowController.barcodeString =
        [@"bitcoin:" stringByAppendingString:[[BCClient sharedClient] walletHash]];
    self.barcodeWindowController.label = [[BCClient sharedClient] walletHash];

    [self zoomBarcodeWindowFromButton:sender];

}

- (void)zoomBarcodeWindowFromButton:(NSButton *)sender {
    CGRect frame = [self.window convertRectToScreen:[sender convertRect:sender.bounds toView:self.window.contentView]];
    [self.barcodeWindowController.window setFrame:frame
                                          display:YES
                                          animate:NO];
    [self.barcodeWindowController showWindow:nil];

    [self.barcodeWindowController.window setFrame:CGRectInset(frame, -BARCODE_ZOOM_SIZE * .5, -BARCODE_ZOOM_SIZE * .5)
                                          display:YES
                                          animate:YES];
}

@end
