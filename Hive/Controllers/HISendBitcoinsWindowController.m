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
#import "HIBitcoinUrlService.h"
#import "HIButtonWithSpinner.h"
#import "HICameraWindowController.h"
#import "HIContactAutocompleteWindowController.h"
#import "HICurrencyFormatService.h"
#import "HIExchangeRateService.h"
#import "HIFeeDetailsViewController.h"
#import "HILinkTextField.h"
#import "HIPasswordInputViewController.h"
#import "HIPerson.h"
#import "HISendBitcoinsWindowController.h"
#import "HITransaction.h"
#import "NSDecimalNumber+HISatoshiConversion.h"
#import "NSWindow+HIShake.h"

#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory+OSX.h>

NSString * const HISendBitcoinsWindowDidClose = @"HISendBitcoinsWindowDidClose";
NSString * const HISendBitcoinsWindowSuccessKey = @"success";

@interface HISendBitcoinsWindowController () <HIExchangeRateObserver, NSPopoverDelegate, HICameraWindowControllerDelegate> {
    HIContact *_contact;
    HIContactAutocompleteWindowController *_autocompleteController;
    NSString *_hashAddress;
    BOOL _lockedAddress;
    satoshi_t _amount;
    NSPopover *_passwordPopover;
}

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

- (id)init {
    self = [super initWithWindowNibName:@"HISendBitcoinsWindowController"];

    if (self) {
        _amount = 0ll;

        _exchangeRateService = [HIExchangeRateService sharedService];
        [_exchangeRateService addExchangeRateObserver:self];
        self.selectedCurrency = _exchangeRateService.preferredCurrency;

        _bitcoinFormatService = [HIBitcoinFormatService sharedService];
        _selectedBitcoinFormat = _bitcoinFormatService.preferredFormat;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateBitcoinFormat:)
                                                     name:HIPreferredFormatChangeNotification
                                                   object:nil];
    }

    return self;
}

- (id)initWithContact:(HIContact *)contact {
    self = [self init];

    if (self) {
        _contact = contact;
    }

    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.window center];

    if (_contact) {
        HIAddress *address = [_contact.addresses anyObject];
        [self selectContact:_contact address:address];
    } else if (_hashAddress) {
        [self setHashAddress:_hashAddress];
    } else {
        [self setHashAddress:@""];

        self.addressLabel.stringValue = NSLocalizedString(@"or choose from the list", @"Autocomplete dropdown prompt");
    }

    if (_lockedAddress) {
        [self lockAddress];
    }

    self.photoView.layer.cornerRadius = 5.0;
    self.photoView.layer.masksToBounds = YES;

    self.wrapper.layer.cornerRadius = 5.0;

    [self setUpQRCodeButton];
    [self setupCurrencyList];

    if (_amount) {
        [self updateFieldsForLockedAmount];
    } else {
        self.amountFieldValue = 0ll;
    }
    [self updateConvertedAmountFromAmount];

    [self updateSendButtonEnabled];
    [self updateInterfaceForExchangeRate];
}

- (void)setUpQRCodeButton {
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
    NSString *hash = _hashAddress ?: self.nameLabel.stringValue;
    self.sendButtonEnabled = self.amountFieldValue > 0 && hash.length > 0;
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
    if ([self isWindowLoaded]) {
        [self clearContact];
        self.nameLabel.stringValue = hash;
    }

    _hashAddress = hash;
}

- (void)lockAddress {
    _lockedAddress = YES;

    if ([self isWindowLoaded]) {
        [self.nameLabel setEditable:NO];
        [self.dropdownButton setHidden:YES];
    }
}

- (void)setLockedAddress:(NSString *)hash {
    [self setHashAddress:hash];
    [self lockAddress];
}

- (void)setLockedAmount:(satoshi_t)amount {
    _amount = amount;
    if ([self isWindowLoaded]) {
        [self updateFieldsForLockedAmount];
    }
}

- (void)updateFieldsForLockedAmount {
    self.amountFieldValue = _amount;
    [self updateConvertedAmountFromAmount];

    [self.amountField setEditable:NO];
    [self.convertedAmountField setEditable:NO];
}

- (void)clearContact {
    _contact = nil;
    _hashAddress = nil;

    self.addressLabel.stringValue = @"";
    self.photoView.image = [NSImage imageNamed:@"avatar-empty"];
}

- (void)selectContact:(id<HIPerson>)contact address:(HIAddress *)address {
    _contact = contact;
    _hashAddress = address.address;

    self.nameLabel.stringValue = contact.name;
    self.addressLabel.stringValue = address.addressWithCaption ?: @"";
    self.photoView.image = _contact.avatarImage;
    [self setQRCodeScanningEnabled:NO];

    [self.window makeFirstResponder:nil];
}


#pragma mark - Text fields

- (void)updateBitcoinFormat:(NSNotification *)notification {
    self.selectedBitcoinFormat = [[HIBitcoinFormatService sharedService] preferredFormat];
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
    return [self.bitcoinFormatService parseString:self.amountField.stringValue
                                       withFormat:self.selectedBitcoinFormat
                                            error:NULL];
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
    NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:self.convertedAmountField.stringValue
                                                                locale:[NSLocale currentLocale]];
    return number == [NSDecimalNumber notANumber] ? [NSDecimalNumber zero] : number;
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
    NSString *feeString = [self.bitcoinFormatService stringForBitcoin:fee withFormat:self.selectedBitcoinFormat];
    feeString = [@"+" stringByAppendingString:feeString];

    NSDictionary *attributes = @{
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:.3 alpha:1.0],
        NSFontAttributeName: [NSFont systemFontOfSize:11],
    };

    self.feeButton.attributedTitle = [[NSAttributedString alloc] initWithString:feeString attributes:attributes];
    self.feeButton.hidden = fee == 0;
    self.feeDetailsViewController.fee = self.currentFee;
}

- (satoshi_t)currentFee {
    return [[BCClient sharedClient] feeWhenSendingBitcoin:self.amountFieldValue];
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

- (void)dropdownButtonClicked:(id)sender {
    if ([sender state] == NSOnState) {
        // focus name label, but don't select whole text, just put the cursor at the end
        [self.window makeFirstResponder:self.nameLabel];
        NSText *editor = [self.window fieldEditor:YES forObject:self.nameLabel];
        [editor setSelectedRange:NSMakeRange(self.nameLabel.stringValue.length, 0)];

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


    NSString *target = _hashAddress ?: self.nameLabel.stringValue;

    if (satoshiWithFee > [[BCClient sharedClient] estimatedBalance]) {
        [self showInsufficientFundsAlert];
    }
    else if (satoshiWithFee > [[BCClient sharedClient] availableBalance]) {
        [self showBlockedFundsAlert];
    }
    else if (target.length == 0) {
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
    NSError *error = nil;

    [[BCClient sharedClient] sendBitcoins:satoshi
                                   toHash:target
                                 password:password
                                    error:&error
                               completion:^(BOOL success, NSString *transactionId) {
        if (success) {
            [self closeAndNotifyWithSuccess:YES transactionId:transactionId];
        } else {
            [self showTransactionErrorAlert];
            [self.sendButton hideSpinner];
        }
    }];

    if (error) {
        if (error.code == kHIBitcoinManagerWrongPassword) {
            [self.window hiShake];
        } else if (error.code == kHIBitcoinManagerSendingDustError) {
            [self showSendingDustAlert];
        } else {
            [self showTransactionErrorAlert];
        }
    } else {
        [self.sendButton showSpinner];
        [self hidePasswordPopover];
    }
}

- (void)closeAndNotifyWithSuccess:(BOOL)success transactionId:(NSString *)transactionId {
    [self.sendButton hideSpinner];

    if (_sendCompletion) {
        _sendCompletion(success, transactionId);
    }

    [self close];

    [[NSNotificationCenter defaultCenter] postNotificationName:HISendBitcoinsWindowDidClose
                                                        object:self
                                                      userInfo:@{HISendBitcoinsWindowSuccessKey: @(success)}];
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

- (void)showBlockedFundsAlert {
    NSAlert *alert = [[NSAlert alloc] init];

    [alert setMessageText:NSLocalizedString(@"Some funds are temporarily unavailable.",
                                            @"Amount exceeds available balance alert title")];

    [alert setInformativeText:NSLocalizedString(@"To send this transaction, you'll need to wait for your pending "
                                                @"transactions to be confirmed first (this shouldn't take more "
                                                @"than a few minutes).",
                                                @"Amount exceeds available balance alert message")];

    [alert addButtonWithTitle:NSLocalizedString(@"OK", @"OK button title")];

    HILinkTextField *link = [[HILinkTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 15)];
    link.stringValue = NSLocalizedString(@"What does this mean?", @"Button to show info about pending funds");
    link.href = @"https://github.com/hivewallet/hive-osx/wiki/Sending-Bitcoin-from-a-pending-transaction";
    link.font = [NSFont systemFontOfSize:11.0];
    [alert setAccessoryView:link];

    [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
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
    NSAlert *alert = [[NSAlert alloc] init];

    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", @"OK button title")];

    [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
}


#pragma mark - NSTextField delegate

- (void)controlTextDidChange:(NSNotification *)notification {
    if (notification.object == self.amountField) {
        [self updateConvertedAmountFromAmount];
        [self updateFee];
        [self updateSendButtonEnabled];
    } else if (notification.object == self.convertedAmountField) {
        [self updateAmountFromConvertedAmount];
    } else {
        [self setQRCodeScanningEnabled:self.nameLabel.stringValue.length == 0];
        [self clearContact];
        [self startAutocompleteForCurrentQuery];
        [self updateSendButtonEnabled];
    }
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
                                                            fromView:self.wrapper];

        popupFrame = NSMakeRect(dialogFrame.origin.x + separatorFrame.origin.x,
                                dialogFrame.origin.y + separatorFrame.origin.y - popupFrame.size.height,
                                separatorFrame.size.width,
                                popupFrame.size.height);

        [popup setFrame:popupFrame display:YES];

        // make the results list window a child of the send window
        // but delay the call until the window fully initializes
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.window addChildWindow:popup ordered:NSWindowAbove];
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
    [self updateSendButtonEnabled];
}


#pragma mark - Passwords

- (BOOL)isPasswordRequired {
    return [BCClient sharedClient].isWalletPasswordProtected;
}

- (void)showPasswordPopover:(NSButton *)sender forSendingBitcoin:(uint64)bitcoin toTarget:(NSString *)target {
    _passwordPopover = [NSPopover new];
    _passwordPopover.behavior = NSPopoverBehaviorTransient;
    _passwordPopover.delegate = self;

    if (!self.passwordInputViewController) {
        self.passwordInputViewController = [HIPasswordInputViewController new];
        self.passwordInputViewController.prompt =
            NSLocalizedString(@"Enter your passphrase to confirm the transaction:", @"Passphrase prompt for sending");
        self.passwordInputViewController.submitLabel =
            NSLocalizedString(@"Confirm", @"Confirm button next to passphrase");
    }

    __unsafe_unretained __typeof__ (self) weakSelf = self;
    self.passwordInputViewController.onSubmit = ^(HIPasswordHolder *passwordHolder) {
        [weakSelf sendBitcoin:bitcoin toTarget:target password:passwordHolder];
    };

    _passwordPopover.contentViewController = self.passwordInputViewController;
    [_passwordPopover showRelativeToRect:sender.bounds
                                  ofView:sender
                           preferredEdge:NSMaxYEdge];
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
              didScanQRCodeURL:(NSString *)QRCodeURL {
    return [[HIBitcoinUrlService sharedService] applyUrlString:QRCodeURL
                                                  toSendWindow:self];
}

@end
