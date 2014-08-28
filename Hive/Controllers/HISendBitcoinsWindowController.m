//
//  HISendBitcoinsWindowController.m
//  Hive
//
//  Created by Jakub Suder on 05.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <BitcoinJKit/BitcoinJKit.h>
#import <BitcoinJKit/HIBitcoinErrorCodes.h>
#import "BCClient.h"
#import "HIAddress.h"
#import "HIBitcoinFormatService.h"
#import "HIBitcoinURIService.h"
#import "HIButtonWithSpinner.h"
#import "HICameraWindowController.h"
#import "HIContactAutocompleteWindowController.h"
#import "HICurrencyFormatService.h"
#import "HIExchangeRateService.h"
#import "HIFeeDetailsViewController.h"
#import "HILinkTextField.h"
#import "HINetworkConnectionMonitor.h"
#import "HIPasswordHolder.h"
#import "HIPasswordInputViewController.h"
#import "HIPerson.h"
#import "HISendBitcoinsWindowController.h"
#import "HITransaction.h"
#import "NSColor+Hive.h"
#import "NSDecimalNumber+HISatoshiConversion.h"
#import "NSAlert+Hive.h"
#import "NSView+Hive.h"
#import "NSWindow+HIShake.h"
#import "HIApplication.h"

#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory+OSX.h>

NSString * const HISendBitcoinsWindowDidClose = @"HISendBitcoinsWindowDidClose";
NSString * const HISendBitcoinsWindowSuccessKey = @"success";

@interface HISendBitcoinsWindowController ()
        <HIExchangeRateObserver, NSPopoverDelegate, HICameraWindowControllerDelegate> {
    HIApplication *_sourceApplication;
    HIContact *_contact;
    HIContactAutocompleteWindowController *_autocompleteController;
    NSString *_hashAddress;
    BOOL _lockedAddress;
    satoshi_t _amount;
    NSPopover *_passwordPopover;
    NSLocale *_locale;
    int _paymentRequestSession;
    NSArray *_detailsSectionConstraints;
    NSString *_savedLabel;
}

@property (strong) IBOutlet NSBox *wrapper;
@property (strong) IBOutlet NSBox *separator;
@property (strong) IBOutlet NSImageView *photoView;
@property (strong) IBOutlet NSImageView *lockIcon;
@property (strong) IBOutlet NSTextField *nameLabel;
@property (strong) IBOutlet NSTextField *addressLabel;
@property (strong) IBOutlet NSTextField *amountField;
@property (strong) IBOutlet NSTextField *convertedAmountField;
@property (strong) IBOutlet NSButton *QRCodeButton;
@property (strong) IBOutlet NSView *currencyRateInfoView;
@property (strong) IBOutlet NSPopUpButton *convertedCurrencyPopupButton;
@property (strong) IBOutlet NSPopUpButton *bitcoinCurrencyPopupButton;
@property (strong) IBOutlet NSButton *feeButton;
@property (strong) IBOutlet NSButton *cancelButton;
@property (strong) IBOutlet NSButton *closeButton;
@property (strong) IBOutlet HIButtonWithSpinner *sendButton;
@property (nonatomic, strong) IBOutlet NSButton *dropdownButton;

@property (nonatomic, assign) IBOutlet NSTextField *detailsLabel;
@property (nonatomic, assign) IBOutlet NSScrollView *detailsBox;
@property (nonatomic, assign) IBOutlet NSBox *detailsSeparator;

@property (nonatomic, strong) IBOutlet NSBox *ackBar;
@property (nonatomic, strong) IBOutlet NSTextField *ackMessage;

@property (nonatomic, strong) IBOutlet NSBox *loadingBox;
@property (nonatomic, strong) IBOutlet NSProgressIndicator *loadingSpinner;

@property (assign) satoshi_t amountFieldValue;
@property (copy) NSDecimalNumber *convertedAmountFieldValue;
@property (copy) NSDecimalNumber *exchangeRate;
@property (nonatomic, copy) NSString *selectedCurrency;
@property (copy, nonatomic) NSString *selectedBitcoinFormat;
@property (strong, readonly) HIExchangeRateService *exchangeRateService;
@property (strong, readonly) HIBitcoinFormatService *bitcoinFormatService;
@property (strong, readonly) HIContactAutocompleteWindowController *autocompleteController;
@property (strong) HIFeeDetailsViewController *feeDetailsViewController;
@property (strong) HIPasswordInputViewController *passwordInputViewController;
@property (strong) NSViewController *currencyRateInfoViewController;
@property (nonatomic, assign) BOOL sendButtonEnabled;

@end

@implementation HISendBitcoinsWindowController

#pragma mark - Init & cleanup

- (instancetype)init {
    self = [super initWithWindowNibName:self.className];

    if (self) {
        _exchangeRateService = [HIExchangeRateService sharedService];
        [_exchangeRateService addExchangeRateObserver:self];
        self.selectedCurrency = _exchangeRateService.preferredCurrency;

        _bitcoinFormatService = [HIBitcoinFormatService sharedService];
        _selectedBitcoinFormat = _bitcoinFormatService.preferredFormat;
        _locale = [NSLocale currentLocale];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateBitcoinFormat:)
                                                     name:HIPreferredFormatChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onLocaleChange)
                                                     name:NSCurrentLocaleDidChangeNotification
                                                   object:nil];
    }

    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.window center];

    self.photoView.layer.cornerRadius = 5.0;
    self.photoView.layer.masksToBounds = YES;
    self.lockIcon.hidden = YES;

    NSView *wrapperContents = self.wrapper.contentView;
    wrapperContents.layer.borderWidth = 1.0;
    wrapperContents.layer.borderColor = [[NSColor colorWithCalibratedWhite:0.8 alpha:1.0] hiNativeColor];
    wrapperContents.layer.backgroundColor = [[NSColor whiteColor] hiNativeColor];
    wrapperContents.layer.cornerRadius = 5.0;

    self.detailsBox.layer.borderWidth = 1.0;
    self.detailsBox.layer.borderColor = [[NSColor colorWithCalibratedWhite:0.85 alpha:1.0] hiNativeColor];
    [[self.detailsBox documentView] setTextContainerInset:NSMakeSize(1.0, 5.0)];

    [self setupQRCodeButton];
    [self setupCurrencyList];
    [self setAmountFieldValue:0];
    [self updateAvatarImage];
    [self updateInterfaceForExchangeRate];
    [self updateSendButtonEnabled];
    [self hideDetailsSection];
}

- (void)showWindow:(id)sender {
    [super showWindow:sender];
    [self focusAppropriateField];
}

- (void)focusAppropriateField {
    if (!_lockedAddress) {
        [self focusFieldAndMoveCursorToEnd:self.nameLabel];
    } else if (!_amount) {
        [self focusFieldAndMoveCursorToEnd:self.amountField];
    } else {
        [self.window makeFirstResponder:nil];
    }
}

- (void)setupQRCodeButton {
    NIKFontAwesomeIconFactory *iconFactory = [NIKFontAwesomeIconFactory new];
    iconFactory.padded = YES;
    iconFactory.size = 14;
    iconFactory.edgeInsets = NSEdgeInsetsMake(2, 0, 0, 0);
    self.QRCodeButton.image = [iconFactory createImageForIcon:NIKFontAwesomeIconQrcode];
}

- (void)setupCurrencyList {
    [self.bitcoinCurrencyPopupButton addItemsWithTitles:self.bitcoinFormatService.availableFormats];
    [self.bitcoinCurrencyPopupButton selectItemWithTitle:self.bitcoinFormatService.preferredFormat];
    [self.convertedCurrencyPopupButton addItemsWithTitles:self.exchangeRateService.availableCurrencies];
    [self.convertedCurrencyPopupButton selectItemWithTitle:_selectedCurrency];
}

- (void)updateSendButtonEnabled {
    self.sendButtonEnabled = self.amountFieldValue > 0 && self.currentRecipient.length > 0;
}

- (void)showDetailsSection {
    [self.wrapper hiRemoveConstraintsMatchingSubviews:^BOOL(NSArray *views) {
        return [views containsObject:self.separator] && [views containsObject:self.detailsSeparator];
    }];

    [self.wrapper addConstraints:_detailsSectionConstraints];

    [self.detailsLabel setHidden:NO];
    [self.detailsBox setHidden:NO];
    [self.detailsSeparator setHidden:NO];
}

- (void)hideDetailsSection {
    [self.detailsLabel setHidden:YES];
    [self.detailsBox setHidden:YES];
    [self.detailsSeparator setHidden:YES];

    NSArray *removed = [self.wrapper hiRemoveConstraintsMatchingSubviews:^BOOL(NSArray *views) {
        BOOL separator = [views containsObject:self.separator] || [views containsObject:self.detailsSeparator];
        return separator && [views containsObject:self.detailsBox];
    }];

    [self.wrapper addConstraint:VSPACE(self.separator, self.detailsSeparator)];

    _detailsSectionConstraints = removed;
}

- (void)windowWillClose:(NSNotification *)notification {
    _autocompleteController = nil;
    [_exchangeRateService removeExchangeRateObserver:self];
    [self cleanUpCameraWindow];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Configuration

- (void)setHashAddress:(NSString *)hash {
    [self clearContact];
    self.nameLabel.stringValue = hash;
    _hashAddress = hash;
}

- (void)lockAddress {
    _lockedAddress = YES;

    [self.nameLabel setEditable:NO];
    [self.dropdownButton setHidden:YES];
    [self setQRCodeScanningEnabled:NO];
    [self updateAvatarImage];
}

- (void)setLockedAddress:(NSString *)hash {
    [self setHashAddress:hash];
    [self lockAddress];
}

- (void)setLockedAmount:(satoshi_t)amount {
    _amount = amount;

    self.amountFieldValue = _amount;
    [self updateConvertedAmountFromAmount];
    [self updateSendButtonEnabled];

    [self.amountField setEditable:NO];
    [self.convertedAmountField setEditable:NO];
}

- (NSString *)detailsText {
    NSString *text = [self.detailsBox.documentView string];
    BOOL hidden = self.detailsBox.isHidden;

    if (!hidden && text.length > 0) {
        return text;
    } else {
        return nil;
    }
}

- (void)setDetailsText:(NSString *)text {
    [self showDetailsSection];

    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [[self.detailsBox documentView] setString:text];
}

- (void)clearContact {
    _contact = nil;
    _hashAddress = nil;

    self.addressLabel.stringValue = @" ";
    [self updateAvatarImage];
}

- (void)setSourceApplication:(HIApplication *)application {
    _sourceApplication = application;

    [self updateAvatarImage];
}

- (void)selectContact:(id<HIPerson>)contact {
    [self selectContact:contact address:[contact.addresses anyObject]];
}

- (void)selectContact:(id<HIPerson>)contact address:(HIAddress *)address {
    _contact = contact;
    _hashAddress = address.address;
    _savedLabel = contact.name;

    self.nameLabel.stringValue = contact.name;
    self.addressLabel.stringValue = address.addressWithCaption ?: @" ";
    [self updateAvatarImage];
    [self setQRCodeScanningEnabled:NO];

    [self.window makeFirstResponder:nil];
}

- (void)usePaymentRequestTitle {
    self.window.title = NSLocalizedString(@"Pay with Bitcoin", @"Send Bitcoin window title for payment request");
}

- (void)showPaymentRequest:(int)sessionId details:(NSDictionary *)data {
    HILogDebug(@"Payment request data loaded: %@", data);

    _paymentRequestSession = sessionId;
    [self usePaymentRequestTitle];

    NSNumber *amount = data[@"amount"];
    NSString *memo = data[@"memo"];
    NSString *paymentURL = data[@"paymentURL"];
    NSString *pkiName = data[@"pkiName"];
    NSString *label = data[@"bitcoinURILabel"];
    NSString *recipientName = nil;

    NSURL *URL = [NSURL URLWithString:paymentURL];

    if (pkiName) {
        recipientName = pkiName;
        self.lockIcon.hidden = NO;
    } else if (URL) {
        recipientName = URL.host;
    } else if (label) {
        recipientName = label;
    }

    if (recipientName) {
        _savedLabel = recipientName;
        [self setLockedAddress:recipientName];
    } else {
        [self setLockedAddress:@"?"];
    }

    if ([amount integerValue] > 0) {
        [self setLockedAmount:amount.integerValue];
    }

    if (memo.length == 0) {
        memo = data[@"bitcoinURIMessage"];
    }

    if (memo.length > 0) {
        [self setDetailsText:memo];
    }

    [self focusAppropriateField];
}

- (void)showPaymentRequestLoadingBox {
    [self usePaymentRequestTitle];

    [self.window.contentView addSubview:self.loadingBox];
    [self.window.contentView addConstraints:@[
                                              INSET_LEADING(self.loadingBox),
                                              INSET_TRAILING(self.loadingBox),
                                              INSET_TOP(self.loadingBox),
                                              INSET_BOTTOM(self.loadingBox)
                                            ]];

    [self.loadingSpinner startAnimation:self];
}

- (void)hidePaymentRequestLoadingBox {
    [self.loadingSpinner stopAnimation:self];
    [self.loadingBox removeFromSuperview];
}

- (void)updateAvatarImage {
    self.photoView.hidden = NO;

    if (_contact.avatar) {
        self.photoView.image = _contact.avatarImage;
    } else if (_sourceApplication.icon) {
        self.photoView.image = _sourceApplication.icon;
    } else if (_lockedAddress) {
        self.photoView.hidden = YES;
    } else {
        self.photoView.image = [NSImage imageNamed:@"avatar-empty"];
    }
}


#pragma mark - Text fields

- (void)updateBitcoinFormat:(NSNotification *)notification {
    self.selectedBitcoinFormat = [[HIBitcoinFormatService sharedService] preferredFormat];
}

- (void)onLocaleChange {
    satoshi_t amount = [self.bitcoinFormatService parseString:self.amountField.stringValue
                                                   withFormat:self.selectedBitcoinFormat
                                                       locale:_locale
                                                        error:NULL];
    self.amountFieldValue = MAX(amount, 0);

    [self updateFee];
    [self updateConvertedAmountFromAmount];

    _locale = [NSLocale currentLocale];
}

- (void)setSelectedBitcoinFormat:(NSString *)selectedBitcoinFormat {
    if (![selectedBitcoinFormat isEqual:_selectedBitcoinFormat]) {
        satoshi_t oldValue = self.amountFieldValue;
        _selectedBitcoinFormat = [selectedBitcoinFormat copy];
        self.amountFieldValue = oldValue;

        self.bitcoinFormatService.preferredFormat = selectedBitcoinFormat;
        self.feeDetailsViewController.bitcoinFormat = selectedBitcoinFormat;
    }
}

- (void)setAmountFieldValue:(satoshi_t)amount {
    self.amountField.stringValue = [self.bitcoinFormatService stringForBitcoin:amount
                                                                    withFormat:self.selectedBitcoinFormat];
    [self updateFee];
}

- (void)formatAmountField {
    [self setAmountFieldValue:self.amountFieldValue];
}

- (satoshi_t)amountFieldValue {
    satoshi_t value = [self.bitcoinFormatService parseString:self.amountField.stringValue
                                                  withFormat:self.selectedBitcoinFormat
                                                       error:NULL];
    return MAX(value, 0);
}

- (void)setConvertedAmountFieldValue:(NSDecimalNumber *)amount {
    NSString *string = [[HICurrencyFormatService sharedService] stringWithUnitForValue:amount
                                                                            inCurrency:self.selectedCurrency];
    [self.convertedAmountField setStringValue:string];
}

- (void)formatConvertedAmountField {
    [self setConvertedAmountFieldValue:self.convertedAmountFieldValue];
}

- (NSDecimalNumber *)convertedAmountFieldValue {
    NSDecimalNumber *number = [[HICurrencyFormatService sharedService] parseString:self.convertedAmountField.stringValue
                                                                             error:NULL];
    NSDecimalNumber *zero = [NSDecimalNumber zero];
    if (!number || number == [NSDecimalNumber notANumber] || [number isLessThanOrEqualTo:zero]) {
        return zero;
    } else {
        return number;
    }
}

- (void)updateConvertedAmountFromAmount {
    if (self.exchangeRate) {
        self.convertedAmountFieldValue = [self convertedAmountForBitcoinAmount:self.amountFieldValue];
    } else {
        self.convertedAmountFieldValue = [NSDecimalNumber zero];
    }
}

- (void)updateAmountFromConvertedAmount {
    if (self.exchangeRate) {
        self.amountFieldValue = [self bitcoinAmountForConvertedAmount:self.convertedAmountFieldValue];
    } else {
        self.amountFieldValue = 0ll;
    }
}


#pragma mark - Currency conversion

- (void)setSelectedCurrency:(NSString *)selectedCurrency {
    _selectedCurrency = [selectedCurrency copy];
    [self fetchExchangeRate];
}

- (void)fetchExchangeRate {
    self.convertedAmountField.enabled = NO;
    self.exchangeRate = nil;
    [self updateConvertedAmountFromAmount];
    [_exchangeRateService updateExchangeRateForCurrency:self.selectedCurrency];
}

- (NSDecimalNumber *)convertedAmountForBitcoinAmount:(satoshi_t)amount {
    return [[NSDecimalNumber hiDecimalNumberWithSatoshi:amount] decimalNumberByMultiplyingBy:self.exchangeRate];
}

- (satoshi_t)bitcoinAmountForConvertedAmount:(NSDecimalNumber *)amount {
    return [amount decimalNumberByDividingBy:self.exchangeRate].hiSatoshi;
}

- (IBAction)currencyChanged:(id)sender {
    self.selectedCurrency = self.convertedCurrencyPopupButton.selectedItem.title;
}

- (IBAction)currencyRateInfoButtonClicked:(id)sender {
    NSPopover *infoPopover = [NSPopover new];
    infoPopover.behavior = NSPopoverBehaviorTransient;

    if (!self.currencyRateInfoViewController) {
        self.currencyRateInfoViewController = [[NSViewController alloc] init];
        self.currencyRateInfoViewController.view = self.currencyRateInfoView;

        NSTextField *label = self.currencyRateInfoView.subviews[0];
        NSString *text = label.stringValue;

        NSDictionary *linkAttributes = @{
                                         NSLinkAttributeName: @"https://bitcoinaverage.com/markets.htm",
                                         NSFontAttributeName: label.font,
                                         NSForegroundColorAttributeName: [NSColor blueColor],
                                         NSUnderlineStyleAttributeName: @(NSSingleUnderlineStyle)
                                       };

        NSDictionary *textAttributes = @{
                                         NSFontAttributeName: label.font
                                       };

        NSMutableAttributedString *richText = [[NSMutableAttributedString alloc] initWithString:text];
        [richText setAttributes:textAttributes range:NSMakeRange(0, text.length)];
        [richText setAttributes:linkAttributes range:[text rangeOfString:@"BitcoinAverage"]];
        [richText setAttributes:linkAttributes range:[text rangeOfString:@"Bitcoin Average"]];

        [label setAllowsEditingTextAttributes:YES];
        [label setAttributedStringValue:richText];
    }

    infoPopover.contentViewController = self.currencyRateInfoViewController;

    [infoPopover showRelativeToRect:[sender bounds]
                             ofView:sender
                      preferredEdge:NSMaxXEdge];
}


#pragma mark - HIExchangeRateObserver

- (void)exchangeRateUpdatedTo:(NSDecimalNumber *)exchangeRate
                  forCurrency:(NSString *)currency {
    if ([currency isEqual:_selectedCurrency]) {
        self.exchangeRate = exchangeRate;
        [self updateInterfaceForExchangeRate];
    }
}

- (void)updateInterfaceForExchangeRate {
    self.convertedAmountField.enabled = YES;
    [self updateConvertedAmountFromAmount];
}


#pragma mark - Fees

- (void)updateFee {
    satoshi_t fee = self.currentFee;
    NSString *feeString;

    if (fee > 0) {
        feeString = [NSString stringWithFormat:@"+%@",
                     [self.bitcoinFormatService stringForBitcoin:fee withFormat:self.selectedBitcoinFormat]];
    } else {
        // we couldn't calculate the fee
        feeString = @"+?";
    }

    NSDictionary *attributes = @{
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:.3 alpha:1.0],
        NSFontAttributeName: [NSFont systemFontOfSize:11],
    };

    self.feeButton.attributedTitle = [[NSAttributedString alloc] initWithString:feeString attributes:attributes];
    self.feeDetailsViewController.fee = self.currentFee;
}

- (satoshi_t)currentFee {
    NSError *error = nil;
    satoshi_t fee = [[BCClient sharedClient] feeWhenSendingBitcoin:self.amountFieldValue
                                                       toRecipient:self.currentRecipient
                                                             error:&error];
    return error ? 0 : fee;
}

- (NSString *)currentRecipient {
    return (_hashAddress ?: self.nameLabel.stringValue);
}

- (IBAction)showFeePopover:(NSButton *)sender {
    NSPopover *feePopover = [NSPopover new];
    feePopover.behavior = NSPopoverBehaviorTransient;

    if (!self.feeDetailsViewController) {
        self.feeDetailsViewController = [HIFeeDetailsViewController new];
        self.feeDetailsViewController.fee = self.currentFee;
        self.feeDetailsViewController.bitcoinFormat = self.selectedBitcoinFormat;
    }

    feePopover.contentViewController = self.feeDetailsViewController;
    [feePopover showRelativeToRect:sender.bounds
                            ofView:sender
                     preferredEdge:NSMaxXEdge];
}


#pragma mark - Handling button clicks

- (void)focusFieldAndMoveCursorToEnd:(NSTextField *)field {
    [self.window makeFirstResponder:field];
    NSText *editor = [self.window fieldEditor:YES forObject:field];
    [editor setSelectedRange:NSMakeRange(field.stringValue.length, 0)];
}

- (void)dropdownButtonClicked:(id)sender {
    if ([sender state] == NSOnState) {
        [self focusFieldAndMoveCursorToEnd:self.nameLabel];

        if (_contact) {
            [self startAutocompleteForCurrentContact];
        } else {
            [self startAutocompleteForCurrentQuery];
        }
    } else {
        [self hideAutocompleteWindow];
    }
}

- (void)cancelClicked:(id)sender {
    [self closeAndNotifyWithSuccess:NO transactionId:nil];
}

- (void)sendClicked:(id)sender {
    satoshi_t satoshi = self.amountFieldValue;
    satoshi_t satoshiWithFee = satoshi + self.currentFee;

    if (![[HIBitcoinManager defaultManager] isConnected]) {
        [self showNoConnectionAlert];
    }
    else if (satoshiWithFee > [[BCClient sharedClient] estimatedBalance]) {
        [self showInsufficientFundsAlert];
    }
    else if (satoshiWithFee > [[BCClient sharedClient] availableBalance]) {
        [self showBlockedFundsAlert];
    }
    else {
        if (_paymentRequestSession > 0) {
            if ([self isPasswordRequired]) {
                [self showPasswordPopover:sender forPaymentRequest:_paymentRequestSession];
            } else {
                [self sendPaymentRequest:_paymentRequestSession password:nil];
            }
        } else {
            NSString *target = self.currentRecipient;

            if (target.length == 0) {
                [self showNoAddressAlert];
            }
            else if (![[HIBitcoinManager defaultManager] isAddressValid:target]) {
                [self showInvalidAddressAlert];
            }
            else if ([[HIBitcoinManager defaultManager].walletAddress isEqual:target]) {
                [self showOwnAddressAlert];
            }
            else if (![HITransaction isAmountWithinExpectedRange:satoshi]) {
                [self showLargeAmountAlertForAmount:satoshi toTarget:target button:sender];
            }
            else {
                [self processSendingBitcoin:satoshi toTarget:target button:sender];
            }
        }
    }
}

- (void)processSendingBitcoin:(uint64)satoshi toTarget:(NSString *)target button:(id)sender {
    if ([self isPasswordRequired]) {
        [self showPasswordPopover:sender forSendingBitcoin:satoshi toTarget:target];
    } else {
        [self sendBitcoin:satoshi toTarget:target password:nil];
    }
}

- (void)largeAmountAlertWasClosed:(NSAlert *)alert result:(NSInteger)result context:(void *)context {
    NSDictionary *data = CFBridgingRelease(context);

    if (result == NSAlertFirstButtonReturn) {
        [self processSendingBitcoin:[data[@"amount"] longLongValue]
                           toTarget:data[@"target"]
                             button:data[@"button"]];
    }
}

- (void)sendBitcoin:(uint64)satoshi toTarget:(NSString *)target password:(HIPasswordHolder *)password {
    NSError *callError = nil;
    BCClient *client = [BCClient sharedClient];
    NSDictionary *metadata = [self storeFiatCurrencyMetadata];

    [client sendBitcoins:satoshi
                  toHash:target
                password:password
                   error:&callError
              completion:^(BOOL success, HITransaction *transaction) {
        if (success) {
            [self saveMetadata:metadata withTransaction:transaction];
            [self closeAndNotifyWithSuccess:YES transactionId:transaction.id];
        } else {
            [self showTransactionErrorAlert];
            [self setSendingMode:NO];
        }
    }];

    if (callError) {
        [self handleSendingError:callError];
    } else {
        [self setSendingMode:YES];
    }
}

- (void)sendPaymentRequest:(int)sessionId password:(HIPasswordHolder *)password {
    NSError *callError = nil;
    BCClient *client = [BCClient sharedClient];
    NSDictionary *metadata = [self storeFiatCurrencyMetadata];

    HILogDebug(@"Submitting payment request...");

    [client submitPaymentRequestWithSessionId:sessionId
                                     password:password
                                        error:&callError
                                   completion:^(NSError *sendError, NSDictionary *data, HITransaction *transaction) {
                                       if (sendError) {
                                           HILogWarn(@"Payment sending failed: %@", sendError);

                                           [self setSendingMode:NO];
                                           [self showPaymentSendErrorAlert];
                                       } else {
                                           [self saveMetadata:metadata withTransaction:transaction];
                                           [self showPaymentConfirmation:data];
                                       }
                                   }];

    if (callError) {
        [self handleSendingError:callError];
    } else {
        [self setSendingMode:YES];
    }
}

- (NSDictionary *)storeFiatCurrencyMetadata {
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];

    if (self.convertedAmountFieldValue) {
        data[@"fiatAmount"] = self.convertedAmountFieldValue;
    }

    if (self.exchangeRate) {
        data[@"fiatRate"] = self.exchangeRate;
    }

    if (self.selectedCurrency) {
        data[@"fiatCurrency"] = self.selectedCurrency;
    }

    return data;
}

- (void)saveMetadata:(NSDictionary *)metadata withTransaction:(HITransaction *)transaction {
    BCClient *client = [BCClient sharedClient];

    transaction.fiatAmount = metadata[@"fiatAmount"];
    transaction.fiatCurrency = metadata[@"fiatCurrency"];
    transaction.fiatRate = metadata[@"fiatRate"];

    if (_savedLabel) {
        transaction.label = _savedLabel;
    }

    NSString *detailsText = [self detailsText];
    if (detailsText) {
        transaction.details = detailsText;
    }

    if (_sourceApplication) {
        [client attachSourceApplication:_sourceApplication toTransaction:transaction];
    }

    [client updateTransaction:transaction];
}

- (void)handleSendingError:(NSError *)error {
    HILogWarn(@"Transaction could not be sent: %@", error);

    if (error.code == kHIBitcoinManagerWrongPassword) {
        [self.window hiShake];
    } else if (error.code == kHIBitcoinManagerSendingDustError) {
        [self showSendingDustAlert];
    } else if (error.code == kHIBitcoinManagerInsufficientMoneyError) {
        [self showInsufficientFundsWithFeeAlert];
    } else if (error.code == kHIBitcoinManagerPaymentRequestExpiredError) {
        [self showPaymentExpiredAlert];
    } else {
        [self showTransactionErrorAlert];
    }
}

- (void)setSendingMode:(BOOL)sending {
    if (sending) {
        [self.sendButton showSpinner];
        [self.cancelButton setEnabled:NO];
        [self hidePasswordPopover];
    } else {
        [self.sendButton hideSpinner];
        [self.cancelButton setEnabled:YES];
    }
}

- (void)closeAndNotifyWithSuccess:(BOOL)success transactionId:(NSString *)transactionId {
    if (_sendCompletion) {
        _sendCompletion(success, transactionId);
    }

    [self close];

    [[NSNotificationCenter defaultCenter] postNotificationName:HISendBitcoinsWindowDidClose
                                                        object:self
                                                      userInfo:@{HISendBitcoinsWindowSuccessKey: @(success)}];
}

- (void)showPaymentConfirmation:(NSDictionary *)data {
    HILogDebug(@"Payment confirmed: %@", data);

    NSString *memo = data[@"memo"];

    if (memo.length > 0) {
        self.ackMessage.stringValue = memo;
    } else {
        [self.ackMessage removeFromSuperview];
    }

    [self.cancelButton removeFromSuperview];
    [self.sendButton removeFromSuperview];
    [self.closeButton setHidden:NO];

    CGFloat padding = self.wrapper.frame.origin.x;
    [self.window.contentView addSubview:self.ackBar];
    [self.window.contentView addConstraints:@[
                                              INSET_LEADING(self.ackBar, padding),
                                              INSET_TRAILING(self.ackBar, padding),
                                              VSPACE(self.wrapper, self.ackBar, padding),
                                              VSPACE(self.ackBar, self.closeButton, padding)
                                            ]];

    NSColor *fillColor = [NSColor colorWithCalibratedHue:95.0/360 saturation:0.5 brightness:1.0 alpha:1.0];
    NSColor *borderColor = [NSColor colorWithCalibratedHue:95.0/360 saturation:0.5 brightness:0.8 alpha:1.0];

    NSView *ackBarContents = self.ackBar.contentView;
    ackBarContents.layer.backgroundColor = [fillColor hiNativeColor];
    ackBarContents.layer.borderColor = [borderColor hiNativeColor];
    ackBarContents.layer.borderWidth = 1.0;
    ackBarContents.layer.cornerRadius = 5.0;

    self.ackBar.alphaValue = 0.0;
    self.closeButton.alphaValue = 0.0;

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.5;
        self.ackBar.animator.alphaValue = 1.0;
        self.closeButton.animator.alphaValue = 1.0;
    } completionHandler:^{}];
}


#pragma mark - Warning and error alerts

- (void)showTransactionErrorAlert {
    [self showAlertWithTitle:NSLocalizedString(@"Transaction could not be completed.",
                                               @"Transaction failed alert title")

                     message:NSLocalizedString(@"No Bitcoin have been taken from your wallet.",
                                               @"Transaction failed alert message")];
}

- (void)showSendingDustAlert {
    [self showAlertWithTitle:NSLocalizedString(@"Transaction could not be completed.",
                                               @"Transaction failed alert title")

                     message:NSLocalizedString(@"This amount is too low to be sent through the network.",
                                               @"Sending dust alert message")];
}

- (void)showInsufficientFundsAlert {
    [self showAlertWithTitle:NSLocalizedString(@"Amount exceeds balance.",
                                               @"Title of an alert when trying to send more than you have")

                     message:NSLocalizedString(@"You cannot send more money than you own.",
                                               @"Details of an alert when trying to send more than you have")];
}

- (void)showInsufficientFundsWithFeeAlert {
    [self showAlertWithTitle:NSLocalizedString(@"Not enough funds left to pay the transaction fee.",
                                               @"Title of an alert when trying to send more than you have with fee")

                     message:NSLocalizedString(@"If you send your whole wallet balance, there's nothing left to pay "
                                               @"the required fee. Try to send a bit less, or split the "
                                               @"transaction into smaller ones.",
                                               @"Alert details when trying to send more than you have with fee")];
}

- (void)showBlockedFundsAlert {
    NSString *title = NSLocalizedString(@"Some funds are temporarily unavailable.",
                                        @"Amount exceeds available balance alert title");

    NSString *message = NSLocalizedString(@"To send this transaction, you'll need to wait for your pending "
                                          @"transactions to be confirmed first (this shouldn't take more "
                                          @"than a few minutes).",
                                          @"Amount exceeds available balance alert message");

    NSAlert *alert = [NSAlert hiOKAlertWithTitle:title message:message];

    HILinkTextField *link = [[HILinkTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 15)];
    link.stringValue = NSLocalizedString(@"What does this mean?", @"Button to show info about pending funds");
    link.href = @"https://github.com/hivewallet/hive-osx/wiki/Sending-Bitcoin-from-a-pending-transaction";
    link.font = [NSFont systemFontOfSize:11.0];
    [alert setAccessoryView:link];

    [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
}

- (void)showNoConnectionAlert {
    [self showAlertWithTitle:NSLocalizedString(@"Hive is not connected to the Bitcoin network.",
                                               @"No network connection alert title")

                     message:NSLocalizedString(@"You need to be connected to the network to send any transactions.",
                                               @"No network connection alert message")];
}

- (void)showNoAddressAlert {
    [self showAlertWithTitle:NSLocalizedString(@"No address entered.",
                                               @"Empty address alert title")

                     message:NSLocalizedString(@"Please enter a valid Bitcoin address or select one "
                                               @"from the dropdown list.",
                                               @"Empty address alert message")];
}

- (void)showInvalidAddressAlert {
    [self showAlertWithTitle:NSLocalizedString(@"This isn't a valid Bitcoin address.",
                                               @"Invalid address alert title")

                     message:NSLocalizedString(@"Please check if you have entered the address correctly.",
                                               @"Invalid address alert message")];
}

- (void)showOwnAddressAlert {
    [self showAlertWithTitle:NSLocalizedString(@"This is your wallet address.",
                                               @"Warning title when trying to send to your own address")

                     message:NSLocalizedString(@"Please enter a different address.",
                                               @"Warning details when trying to send to your own address")];
}

- (void)showPaymentExpiredAlert {
    [self showAlertWithTitle:NSLocalizedString(@"Payment request has already expired.",
                                               @"Alert title when the time limit to complete the payment has passed")

                     message:NSLocalizedString(@"You'll need to return to the site that requested the payment "
                                               @"and initiate the payment again.",
                                               @"Alert message when the time limit to complete the payment has passed")];
}

- (void)showPaymentSendErrorAlert {
    [self showAlertWithTitle:NSLocalizedString(@"Payment could not be completed.",
                                               @"Alert title when payment can't be sent to the merchant")

                     message:NSLocalizedString(@"Check your network connection, try again later "
                                               @"or report the problem to the payment recipient.",
                                               @"Alert message when payment request can't be loaded from "
                                               @"or sent to the server")];
}

- (void)showLargeAmountAlertForAmount:(satoshi_t)satoshi toTarget:(NSString *)target button:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];

    NSString *formattedBitcoinAmount = [NSString stringWithFormat:@"%@ %@",
                                        self.amountField.stringValue,
                                        self.selectedBitcoinFormat];

    NSString *formattedFiatAmount = [NSString stringWithFormat:@"%@ %@",
                                     self.convertedAmountField.stringValue,
                                     self.selectedCurrency];

    NSString *title = [NSString stringWithFormat:
                       NSLocalizedString(@"Are you sure you want to send %@ (%@) to %@?",
                                         @"Warning when trying to a large BTC amount (btc, fiat amount and address)"),
                       formattedBitcoinAmount, formattedFiatAmount, self.nameLabel.stringValue];

    [alert setMessageText:title];
    [alert setInformativeText:NSLocalizedString(@"This is more than what you usually send.",
                                                @"Warning details when trying to send a large BTC amount")];

    [alert addButtonWithTitle:NSLocalizedString(@"Send", @"Send button title")];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button title")];

    NSDictionary *context = @{@"amount": @(satoshi), @"target": target, @"button": sender};

    [alert beginSheetModalForWindow:self.window
                      modalDelegate:self
                     didEndSelector:@selector(largeAmountAlertWasClosed:result:context:)
                        contextInfo:((void *) CFBridgingRetain(context))];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    NSAlert *alert = [NSAlert hiOKAlertWithTitle:title message:message];

    [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
}


#pragma mark - NSTextField delegate

- (void)controlTextDidChange:(NSNotification *)notification {
    if (notification.object == self.amountField) {
        [self updateConvertedAmountFromAmount];
    } else if (notification.object == self.convertedAmountField) {
        [self updateAmountFromConvertedAmount];
    } else {
        [self setQRCodeScanningEnabled:self.nameLabel.stringValue.length == 0];
        [self clearContact];
        [self startAutocompleteForCurrentQuery];
    }

    [self updateFee];
    [self updateSendButtonEnabled];
}

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    if (notification.object == self.amountField) {
        [self formatAmountField];
    } else if (notification.object == self.convertedAmountField) {
        [self formatConvertedAmountField];
    } else {
        [self hideAutocompleteWindow];
    }
}


#pragma mark - Autocomplete

- (HIContactAutocompleteWindowController *)autocompleteController {
    if (!_autocompleteController) {
        _autocompleteController = [[HIContactAutocompleteWindowController alloc] init];
        _autocompleteController.delegate = self;
    }

    return _autocompleteController;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)selector {
    if (control == self.nameLabel && selector == @selector(moveUp:)) {
        [self showAutocompleteWindow];
        [self.autocompleteController moveSelectionUp];
    } else if (control == self.nameLabel && selector == @selector(moveDown:)) {
        [self showAutocompleteWindow];
        [self.autocompleteController moveSelectionDown];
    } else if (control == self.nameLabel && selector == @selector(insertNewline:)) {
        [self.autocompleteController confirmSelection];
        [self.window makeFirstResponder:self.amountField];
    } else if (control != self.nameLabel && selector == @selector(insertNewline:)) {
        [self.window makeFirstResponder:nil];
    } else if (selector == @selector(cancelOperation:)) {
        if (self.autocompleteController.window.isVisible) {
            [self hideAutocompleteWindow];
        } else {
            // pass it to the cancel button
            return NO;
        }
    } else {
        // let the text field handle the key event
        return NO;
    }

    return YES;
}

- (void)startAutocompleteForCurrentQuery {
    NSString *query = self.nameLabel.stringValue;

    [self showAutocompleteWindow];
    [self.autocompleteController searchWithQuery:query];
}

- (void)startAutocompleteForCurrentContact {
    [self showAutocompleteWindow];
    [self.autocompleteController searchWithContact:_contact];
}

- (void)showAutocompleteWindow {
    NSWindow *popup = self.autocompleteController.window;

    if (!popup.isVisible) {
        NSRect dialogFrame = self.window.frame;
        NSRect popupFrame = popup.frame;
        NSRect separatorFrame = [self.window.contentView convertRect:self.separator.frame
                                                            fromView:self.separator.superview];

        popupFrame = NSMakeRect(dialogFrame.origin.x + separatorFrame.origin.x + 1,
                                dialogFrame.origin.y + separatorFrame.origin.y - popupFrame.size.height,
                                separatorFrame.size.width - 2,
                                popupFrame.size.height);

        [popup setFrame:popupFrame display:YES];

        // make the results list window a child of the send window
        // but delay the call until the window fully initializes
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL wasVisible = popup.isVisible;
            [self.window addChildWindow:popup ordered:NSWindowAbove];

            // addChildWindow: has the side effect of making the window visible,
            // so hide if it it was supposed to be hidden (i.e. when there were no results found)
            [popup setIsVisible:wasVisible];
        });
    }

    self.dropdownButton.state = NSOnState;
}

- (void)hideAutocompleteWindow {
    [self.autocompleteController close];

    self.dropdownButton.state = NSOffState;
}

- (void)addressSelectedInAutocomplete:(HIAddress *)address {
    [self selectContact:address.contact address:address];
    [self hideAutocompleteWindow];
    [self updateFee];
    [self updateSendButtonEnabled];
}


#pragma mark - Passwords

- (BOOL)isPasswordRequired {
    return [BCClient sharedClient].isWalletPasswordProtected;
}

- (NSPopover *)preparePasswordPopover {
    NSPopover *popover = [NSPopover new];
    popover.behavior = NSPopoverBehaviorTransient;
    popover.delegate = self;

    if (!self.passwordInputViewController) {
        self.passwordInputViewController = [HIPasswordInputViewController new];
        self.passwordInputViewController.prompt =
            NSLocalizedString(@"Enter your password to confirm the transaction:", @"Password prompt for sending");
        self.passwordInputViewController.submitLabel =
            NSLocalizedString(@"Confirm", @"Confirm button in password entry form");
    }

    popover.contentViewController = self.passwordInputViewController;
    return popover;
}

- (void)showPasswordPopover:(NSButton *)sender forSendingBitcoin:(uint64)bitcoin toTarget:(NSString *)target {
    _passwordPopover = [self preparePasswordPopover];

    __unsafe_unretained __typeof__ (self) weakSelf = self;
    self.passwordInputViewController.onSubmit = ^(HIPasswordHolder *passwordHolder) {
        [weakSelf sendBitcoin:bitcoin toTarget:target password:passwordHolder];
    };

    [_passwordPopover showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSMaxYEdge];
}

- (void)showPasswordPopover:(NSButton *)sender forPaymentRequest:(int)sessionId {
    _passwordPopover = [self preparePasswordPopover];

    __unsafe_unretained __typeof__ (self) weakSelf = self;
    self.passwordInputViewController.onSubmit = ^(HIPasswordHolder *passwordHolder) {
        [weakSelf sendPaymentRequest:sessionId password:passwordHolder];
    };

    [_passwordPopover showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSMaxYEdge];
}

- (void)hidePasswordPopover {
    [_passwordPopover close];
}


#pragma mark - NSPopoverDelegate

- (void)popoverDidClose:(NSNotification *)notification {
    if (notification.object == _passwordPopover) {
        [self.passwordInputViewController resetInput];
        _passwordPopover = nil;
    }
}

#pragma mark - QR code

- (IBAction)scanQRCode:(id)sender {
    [HICameraWindowController sharedCameraWindowController].delegate = self;
    [[HICameraWindowController sharedCameraWindowController] showWindow:nil];
}

- (void)setQRCodeScanningEnabled:(BOOL)enabled {
    self.QRCodeButton.hidden = !enabled;
    if (!enabled) {
        [self cleanUpCameraWindow];
    }
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
    return [[HIBitcoinURIService sharedService] applyURIString:QRCodeURI
                                                  toSendWindow:self];
}

@end
