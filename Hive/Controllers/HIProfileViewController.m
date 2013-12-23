//
//  HIProfileViewController.m
//  Hive
//
//  Created by Jakub Suder on 30.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HIBitcoinFormatService.h"
#import "HIContactInfoViewController.h"
#import "HICurrencyAmountFormatter.h"
#import "HIExchangeRateService.h"
#import "HIProfile.h"
#import "HIProfileViewController.h"
#import "NSColor+Hive.h"

@interface HIProfileViewController () <HIExchangeRateObserver> {
    HIProfile *_profile;
    HICurrencyAmountFormatter *_amountFormatter;
    HIContactInfoViewController *_infoPanel;
}

@property (strong, readonly) HIExchangeRateService *exchangeRateService;
@property (strong, readonly) HIBitcoinFormatService *bitcoinFormatService;
@property (copy) NSDecimalNumber *exchangeRate;
@property (copy, nonatomic) NSString *selectedCurrency;
@property (copy) NSDecimalNumber *balance;
@property (copy) NSDecimalNumber *pendingBalance;

@property (strong) IBOutlet NSImageView *photoView;
@property (strong) IBOutlet NSTextField *nameLabel;
@property (strong) IBOutlet NSTextField *balanceLabel;
@property (strong) IBOutlet NSTextField *convertedBalanceLabel;
@property (strong) IBOutlet NSPopUpButton *convertedCurrencyPopupButton;
@property (strong) IBOutlet NSPopUpButton *bitcoinCurrencyPopupButton;
@property (strong) IBOutlet NSView *contentView;

@end

@implementation HIProfileViewController

- (id)init {
    self = [super initWithNibName:@"HIProfileViewController" bundle:nil];

    if (self) {
        self.iconName = @"your-profile";

        _profile = [HIProfile new];
        _amountFormatter = [[HICurrencyAmountFormatter alloc] init];
        _infoPanel = [[HIContactInfoViewController alloc] initWithParent:self];

        [[BCClient sharedClient] addObserver:self
                                  forKeyPath:@"balance"
                                     options:NSKeyValueObservingOptionInitial
                                     context:NULL];
        [[BCClient sharedClient] addObserver:self
                                  forKeyPath:@"pendingBalance"
                                     options:NSKeyValueObservingOptionInitial
                                     context:NULL];

        _exchangeRateService = [HIExchangeRateService sharedService];
        [_exchangeRateService addExchangeRateObserver:self];
        self.selectedCurrency = _exchangeRateService.preferredCurrency;

        _bitcoinFormatService = [HIBitcoinFormatService sharedService];
    }

    return self;
}

- (void)dealloc {
    [[BCClient sharedClient] removeObserver:self forKeyPath:@"balance"];
    [[BCClient sharedClient] removeObserver:self forKeyPath:@"pendingBalance"];
    [_exchangeRateService removeExchangeRateObserver:self];
}

- (void)loadView {
    [super loadView];
    [_infoPanel loadView];

    self.view.layer.backgroundColor = [[NSColor hiWindowBackgroundColor] hiNativeColor];

    [self setupCurrencyLists];
    [self updateBalance];
    [self refreshData];

    [self showControllerInContentView:_infoPanel];

}

- (void)setupCurrencyLists {
    [self.bitcoinCurrencyPopupButton addItemsWithTitles:self.bitcoinFormatService.availableFormats];
    [self.convertedCurrencyPopupButton addItemsWithTitles:self.exchangeRateService.availableCurrencies];
    [self.convertedCurrencyPopupButton selectItemWithTitle:_selectedCurrency];
}

- (void)viewWillAppear {
    [self refreshData];
}

- (void)refreshData {
    self.title = NSLocalizedString(@"Profile", @"Profile view title string");

    self.nameLabel.stringValue = _profile.name;
    self.photoView.image = _profile.avatarImage;

    [_infoPanel configureViewForContact:_profile];
}

- (void)showControllerInContentView:(NSViewController *)controller {
    [[_contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    controller.view.frame = _contentView.bounds;
    [_contentView addSubview:controller.view];
}

- (void)updateBalance {
    self.balance = [NSDecimalNumber decimalNumberWithMantissa:[[BCClient sharedClient] balance]
                                                     exponent:-8
                                                   isNegative:NO];

    self.pendingBalance = [NSDecimalNumber decimalNumberWithMantissa:[[BCClient sharedClient] pendingBalance]
                                                            exponent:-8
                                                          isNegative:NO];

    [self updateBalanceLabel];
    [self updateConvertedBalanceLabel];
}

- (void)updateBalanceLabel {
    if ([self.pendingBalance isGreaterThan:[NSDecimalNumber decimalNumberWithString:@"0"]]) {
        self.balanceLabel.stringValue =
            [NSString stringWithFormat:@"%@ (+%@ %@)",
                                       [_amountFormatter stringFromNumber:self.balance],
                                       [_amountFormatter stringFromNumber:self.pendingBalance],
                                       NSLocalizedString(@"pending",
                                       @"part of the balance amount that isn't available")];
    } else {
        self.balanceLabel.stringValue = [_amountFormatter stringFromNumber:self.balance];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (object == [BCClient sharedClient]) {
        if ([keyPath isEqual:@"balance"] || [keyPath isEqual:@"pendingBalance"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateBalance];
            });
        }
    }
}

#pragma mark - converted balance

- (void)setSelectedCurrency:(NSString *)selectedCurrency {
    _selectedCurrency = [selectedCurrency copy];
    self.exchangeRateService.preferredCurrency = selectedCurrency;
    [self fetchExchangeRate];
}

- (void)fetchExchangeRate {
    // TODO: There should be a timer updating the exchange rate in case the window is open too long.
    self.exchangeRate = nil;
    [self updateConvertedBalanceLabel];
    [self.exchangeRateService updateExchangeRateForCurrency:self.selectedCurrency];
}

- (void)updateConvertedBalanceLabel {
    if (self.exchangeRate) {
        NSDecimalNumber *convertedBalance = [self convertedAmountForBitcoinAmount:self.balance];
        self.convertedBalanceLabel.stringValue =
            [_exchangeRateService formatValue:convertedBalance inCurrency:self.selectedCurrency];
    } else {
        self.convertedBalanceLabel.stringValue = @"?";
    }
}

- (NSDecimalNumber *)convertedAmountForBitcoinAmount:(NSDecimalNumber *)amount {
    return [amount decimalNumberByMultiplyingBy:self.exchangeRate];
}

- (IBAction)currencyChanged:(id)sender {
    self.selectedCurrency = self.convertedCurrencyPopupButton.selectedItem.title;
}

#pragma mark - HIExchangeRateObserver

- (void)exchangeRateUpdatedTo:(NSDecimalNumber *)exchangeRate
                  forCurrency:(NSString *)currency {
    if ([currency isEqual:self.selectedCurrency]) {
        self.exchangeRate = exchangeRate;
        [self updateConvertedBalanceLabel];
    }
}

@end
