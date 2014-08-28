//
//  HITransactionPopoverViewController.m
//  Hive
//
//  Created by Jakub Suder on 11/08/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HIBitcoinFormatService.h"
#import "HICurrencyFormatService.h"
#import "HITransaction.h"
#import "HITransactionPopoverViewController.h"
#import "NSView+Hive.h"


@interface HITransactionPopoverViewController () <NSPopoverDelegate>

@property (weak) IBOutlet NSTextField *transactionIdField;
@property (weak) IBOutlet NSTextField *statusField;
@property (weak) IBOutlet NSTextField *confirmationsField;

@property (weak) IBOutlet NSBox *separatorAboveMetadataFields;
@property (weak) IBOutlet NSTextField *amountField;
@property (weak) IBOutlet NSTextField *exchangeRateField;
@property (weak) IBOutlet NSTextField *recipientField;
@property (weak) IBOutlet NSTextField *detailsField;
@property (weak) IBOutlet NSTextField *targetAddressField;
@property (weak) IBOutlet NSTextField *targetAddressLabel;
@property (weak) IBOutlet NSButton *shareButton;

@property (strong) HITransaction *transaction;
@property (strong) NSDictionary *transactionData;

@end


@implementation HITransactionPopoverViewController

- (instancetype)initWithTransaction:(HITransaction *)transaction {
    self = [super initWithNibName:self.className bundle:[NSBundle mainBundle]];

    if (self) {
        self.transaction = transaction;
    }

    return self;
}


#pragma mark - Managing the popover

- (NSPopover *)createPopover {
    NSPopover *popover = [[NSPopover alloc] init];
    popover.contentViewController = self;
    popover.delegate = self;
    popover.behavior = NSPopoverBehaviorTransient;
    return popover;
}

- (void)popoverDidClose:(NSNotification *)notification {
    id<HITransactionPopoverDelegate> delegate = self.delegate;

    if (delegate && [delegate respondsToSelector:@selector(transactionPopoverDidClose:)]) {
        [delegate transactionPopoverDidClose:self];
    }
}


#pragma mark - Configuring the view

- (void)awakeFromNib {
    if (self.transaction.id) {
        self.transactionData = [[BCClient sharedClient] transactionDefinitionWithHash:self.transaction.id];
    }

    self.transactionIdField.stringValue = self.transaction.id ?: @"?";
    self.confirmationsField.stringValue = [self confirmationSummary];
    self.statusField.stringValue = [self transactionStatus];
    self.amountField.stringValue = [self amountSummary];

    if (self.transaction.fiatCurrency && self.transaction.fiatRate) {
        self.exchangeRateField.stringValue = [self exchangeRateSummary];
    } else {
        [self hideField:self.exchangeRateField];
    }

    if (self.transaction.label) {
        self.recipientField.stringValue = self.transaction.label;
    } else {
        [self hideField:self.recipientField];
    }

    if (self.transaction.details) {
        [self.detailsField setStringValue:self.transaction.details];
        [self layoutScrollViewForField:self.detailsField];
    } else {
        [self hideField:self.detailsField];
    }

    // a little hax to include both variants in the XIB's strings file instead of Localizable.strings -
    // one variant is the default text and the other is stored in the placeholder string
    if (self.transaction.direction == HITransactionDirectionIncoming) {
        self.targetAddressLabel.stringValue = [self.targetAddressLabel.cell placeholderString];
    }

    self.targetAddressField.stringValue = [self targetAddress];

    if ([self isSharingSupported]) {
        [self configureShareButton];
    } else {
        [self.shareButton setHidden:YES];
    }
}

- (void)hideField:(NSView *)field {
    // views have tags in pairs, 101+102, 103+104 etc.
    NSInteger fieldTag = field.tag;
    NSInteger labelTag = fieldTag - 1;
    NSAssert(fieldTag > 100, @"Field must have a tag above 100.");
    NSAssert(fieldTag % 2 == 0, @"The value part of the field must have an even tag.");

    NSView *label = [self.view viewWithTag:labelTag];
    NSAssert(label != nil, @"Label view must exist");

    field = [self getWrappingView:field];

    // hide the label+value pair
    [field setHidden:YES];
    [label setHidden:YES];

    // remove their constraints
    [self.view hiRemoveConstraintsMatchingSubviews:^BOOL(NSArray *views) {
        return [views containsObject:label] || [views containsObject:field];
    }];

    // find the previous field
    NSView *previousField = field;
    NSInteger previousFieldTag = fieldTag;
    while (previousField && previousField.isHidden) {
        previousFieldTag -= 2;
        previousField = [self getWrappingView:[self.view viewWithTag:previousFieldTag]];
    }

    // find the next label
    NSView *nextLabel = label;
    NSInteger nextLabelTag = labelTag;
    while (nextLabel && nextLabel.isHidden) {
        nextLabelTag += 2;
        nextLabel = [self.view viewWithTag:nextLabelTag];
    }

    // connect them to each other instead
    NSView *separator = self.separatorAboveMetadataFields;

    NSString *constraintFormat;
    NSDictionary *viewDictionary;

    if (!previousField) {
        viewDictionary = NSDictionaryOfVariableBindings(separator, nextLabel);
        constraintFormat = @"V:[separator]-[nextLabel]";
    } else if (!nextLabel) {
        viewDictionary = NSDictionaryOfVariableBindings(previousField);
        constraintFormat = @"V:[previousField]-|";
    } else {
        viewDictionary = NSDictionaryOfVariableBindings(previousField, nextLabel);
        constraintFormat = @"V:[previousField]-[nextLabel]";
    }

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:constraintFormat
                                                                      options:0
                                                                      metrics:nil
                                                                        views:viewDictionary]];
}

- (void)layoutScrollViewForField:(NSTextField *)field {
    NSScrollView *scrollView = (NSScrollView *) [self getWrappingView:field];
    CGFloat height = MAX(30.0, field.intrinsicContentSize.height + 5.0);

    if (height < scrollView.frame.size.height) {
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[scroll(height)]"
                                                                       options:0
                                                                       metrics:@{@"height": @(height)}
                                                                         views:@{@"scroll": scrollView}];
        [self.view addConstraints:constraints];
    }
}

- (NSView *)getWrappingView:(NSView *)view {
    while (view && view.superview != self.view) {
        view = view.superview;
    }

    return view;
}

- (BOOL)isSharingSupported {
    return NSClassFromString(@"NSSharingServicePicker") != nil;
}

- (void)configureShareButton {
    [self.shareButton sendActionOn:NSLeftMouseDownMask];

    SInt32 major = 0;
    SInt32 minor = 0;
    Gestalt(gestaltSystemVersionMajor, &major);
    Gestalt(gestaltSystemVersionMinor, &minor);

    if (major == 10 && minor < 10) {
        // the "Bevel" button style looks nice on Yosemite, but ugly on pre-Yosemite systems
        [self.shareButton.cell setBezelStyle:NSTexturedRoundedBezelStyle];
    }
}

- (NSAttributedString *)shareText {
    // TODO: Actually add something transaction specific?
    static NSAttributedString *sentString = nil, *receivedString = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        NSString *link = @" http://hivewallet.com";

        NSString *text = NSLocalizedString(@"I've just sent some Bitcoin using Hive",
                                           @"Share sent transaction text");
        sentString = [[NSAttributedString alloc] initWithString:[text stringByAppendingString:link]];

        text = NSLocalizedString(@"I've just received some Bitcoin using Hive",
                                 @"Share sent transaction text");
        receivedString = [[NSAttributedString alloc] initWithString:[text stringByAppendingString:link]];
    });

    return self.transaction.isIncoming ? receivedString : sentString;
}

- (NSString *)transactionStatus {
    HITransactionStatus status = self.transaction.status;

    if (self.transaction.paymentRequestURL &&
        (status == HITransactionStatusUnknown || status == HITransactionStatusPending)) {

        return NSLocalizedString(@"Sent directly to recipient",
                                 @"Status for transaction sent via payment request");
    }

    switch (status) {
        case HITransactionStatusUnknown:
            return NSLocalizedString(@"Not broadcasted yet",
                                     @"Status for transaction not sent to any peers in transaction popup");

        case HITransactionStatusPending: {
            NSInteger peers = [self.transactionData[@"peers"] integerValue];

            if (peers == 0) {
                return NSLocalizedString(@"Not broadcasted yet",
                                         @"Status for transaction not sent to any peers in transaction popup");
            } else {
                return NSLocalizedString(@"Waiting for confirmation",
                                         @"Status for transaction sent to some peers in transaction popup");
            }
        }

        case HITransactionStatusBuilding:
            return NSLocalizedString(@"Confirmed",
                                     @"Status for transaction included in a block in transaction popup");

        case HITransactionStatusDead:
            return NSLocalizedString(@"Rejected by the network",
                                     @"Status for transaction removed from the main blockchain in transaction popup");
    }
}

- (NSString *)targetAddress {
    return self.transaction.targetAddress ?: [[BCClient sharedClient] walletHash] ?: @"?";
}

- (NSString *)confirmationSummary {
    NSInteger confirmations = [self.transactionData[@"confirmations"] integerValue];

    if (confirmations > 100) {
        return @"100+";
    } else {
        return [NSString stringWithFormat:@"%ld", confirmations];
    }
}

- (NSString *)amountSummary {
    satoshi_t satoshiAmount = self.transaction.absoluteAmount;
    NSString *btcAmount = [[HIBitcoinFormatService sharedService] stringForBitcoin:satoshiAmount withFormat:@"BTC"];

    if (self.transaction.fiatCurrency && self.transaction.fiatAmount) {
        HICurrencyFormatService *fiatFormatter = [HICurrencyFormatService sharedService];
        NSString *fiatAmount = [fiatFormatter stringWithUnitForValue:self.transaction.fiatAmount
                                                          inCurrency:self.transaction.fiatCurrency];

        return [NSString stringWithFormat:@"%@ BTC (%@)", btcAmount, fiatAmount];
    } else {
        return [NSString stringWithFormat:@"%@ BTC", btcAmount];
    }
}

- (NSString *)exchangeRateSummary {
    HICurrencyFormatService *fiatFormatter = [HICurrencyFormatService sharedService];
    NSString *oneBTCRate = [fiatFormatter stringWithUnitForValue:self.transaction.fiatRate
                                                      inCurrency:self.transaction.fiatCurrency];

    return [NSString stringWithFormat:@"1 BTC = %@", oneBTCRate];
}


#pragma mark - Action handlers

- (IBAction)showOnBlockchainInfoClicked:(id)sender {
    NSString *url = [NSString stringWithFormat:@"https://blockchain.info/tx/%@", self.transaction.id];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];

    [sender setState:NSOnState];
}

- (IBAction)shareButtonPressed:(NSButton *)sender {
    #pragma deploymate push "ignored-api-availability"
    NSSharingServicePicker *sharingServicePicker = [[NSSharingServicePicker alloc] initWithItems:@[[self shareText]]];
    [sharingServicePicker showRelativeToRect:sender.bounds
                                      ofView:sender
                               preferredEdge:CGRectMaxXEdge];
    #pragma deploymate pop
}

@end
