#import "HIAddressesBox.h"

#import "BCClient.h"
#import "HIAddress.h"
#import "HIBox.h"
#import "HICopyView.h"
#import "HIProfile.h"
#import "HIQRCodeWindowController.h"
#import "NSColor+Hive.h"

#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory+OSX.h>

static const NSInteger AddressFieldTag = 2;
static const double QR_CODE_ZOOM_SIZE = 400;

static NSString *const KEY_WALLET_HASH = @"walletHash";

@interface HIAddressesBox ()

@property (nonatomic, strong, readonly) HIBox *box;
@property (nonatomic, strong, readonly) NSMutableArray *contentViews;
@property (nonatomic, strong, readonly) NSButton *QRCodeButton;
@property (nonatomic, strong) NSTrackingArea *trackingArea;
@property (nonatomic, strong) HIQRCodeWindowController *QRCodeWindowController;

@end


@implementation HIAddressesBox

- (instancetype)initWithFrame:(NSRect)frameRect {
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
        [self setUpQRCodeButton];
    }

    return self;
}

- (void)setUpQRCodeButton {
    _QRCodeButton = [NSButton new];
    _QRCodeButton.bezelStyle = NSSmallSquareBezelStyle;
    _QRCodeButton.translatesAutoresizingMaskIntoConstraints = NO;
    NIKFontAwesomeIconFactory *iconFactory = [NIKFontAwesomeIconFactory new];
    iconFactory.size = 14;
    _QRCodeButton.image = [iconFactory createImageForIcon:NIKFontAwesomeIconQrcode];
    _QRCodeButton.target = self;
    _QRCodeButton.action = @selector(showQRCodeWindow:);

    [self addSubview:_QRCodeButton];
    [_QRCodeButton addConstraint:PIN_WIDTH(_QRCodeButton, 21)];
    [_QRCodeButton addConstraint:PIN_HEIGHT(_QRCodeButton, 21)];
    [self addConstraint:INSET_BOTTOM(_QRCodeButton, 10)];
    [self addConstraint:INSET_RIGHT(_QRCodeButton, 10)];
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
        [self addSubview:view positioned:NSWindowBelow relativeTo:self.QRCodeButton];
    }

    [self invalidateIntrinsicContentSize];
}

- (NSView *)addressSeparatorViewAtIndex:(NSInteger)index {
    NSRect frame = NSMakeRect(1, 60 * index, self.bounds.size.width - 2, 1);
    NSView *separator = [[NSView alloc] initWithFrame:frame];

    separator.wantsLayer = YES;
    separator.layer.backgroundColor = [[NSColor colorWithCalibratedWhite:0.5 alpha:0.3] CGColor];
    separator.autoresizingMask = NSViewMaxYMargin | NSViewWidthSizable;

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
    [nameField setFont:[NSFont boldSystemFontOfSize:13.0]];
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
    [addressField setFont:[NSFont systemFontOfSize:12.0]];
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
    return CGSizeMake(NSViewNoInstrinsicMetric, MAX(15, 60 * self.addresses.count));
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
    self.QRCodeButton.hidden = !self.showsQRCode || !mouseInside;
}

#pragma mark - QR code window

- (void)showQRCodeWindow:(NSButton *)sender {
    NSString *address = [[BCClient sharedClient] walletHash];
    HIProfile *profile = [[HIProfile alloc] init];
    NSString *bitcoinURI;

    if (profile.hasName) {
        bitcoinURI = [NSString stringWithFormat:@"bitcoin:%@?label=%@",
                      address,
                      [profile.name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    } else {
        bitcoinURI = [NSString stringWithFormat:@"bitcoin:%@", address];
    }

    self.QRCodeWindowController = [HIQRCodeWindowController new];
    self.QRCodeWindowController.QRCodeString = bitcoinURI;
    self.QRCodeWindowController.label = address;

    [self zoomQRCodeWindowFromButton:sender];
}

- (void)zoomQRCodeWindowFromButton:(NSButton *)sender {
    CGRect frame = [self.window convertRectToScreen:[sender convertRect:sender.bounds toView:self.window.contentView]];
    [self.QRCodeWindowController.window setFrame:frame
                                         display:YES
                                         animate:NO];

    [self.QRCodeWindowController showWindow:nil];

    NSScreen *screen = self.QRCodeWindowController.window.screen;
    CGRect zoomedFrame = CGRectInset(frame, -QR_CODE_ZOOM_SIZE * .5, -QR_CODE_ZOOM_SIZE * .5);

    // make sure the zoomed view doesn't go over the right edge
    if (CGRectGetMaxX(zoomedFrame) > screen.frame.origin.x + screen.frame.size.width) {
        CGFloat diff = CGRectGetMaxX(zoomedFrame) - (screen.frame.origin.x + screen.frame.size.width);
        zoomedFrame = CGRectOffset(zoomedFrame, -diff, 0);
    }

    [self.QRCodeWindowController.window setFrame:zoomedFrame
                                         display:YES
                                         animate:YES];
}

@end
