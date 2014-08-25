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

@property (weak) IBOutlet NSTextField *amountField;
@property (weak) IBOutlet NSTextField *amountLabel;
@property (weak) IBOutlet NSTextField *exchangeRateField;
@property (weak) IBOutlet NSTextField *exchangeRateLabel;
@property (weak) IBOutlet NSTextField *targetAddressField;
@property (weak) IBOutlet NSTextField *targetAddressLabel;

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

- (NSPopover *)createPopover {
    NSPopover *popover = [[NSPopover alloc] init];
    popover.contentViewController = self;
    popover.delegate = self;
    popover.behavior = NSPopoverBehaviorTransient;
    return popover;
}

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
        [self.exchangeRateField setHidden:YES];
        [self.exchangeRateLabel setHidden:YES];

        [self.view hiRemoveConstraintsMatchingSubviews:^BOOL(NSArray *views) {
            return [views containsObject:self.exchangeRateLabel];
        }];

        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[a]-[t]"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:@{@"a": self.amountLabel,
                                                                                    @"t": self.targetAddressLabel}]];
    }

    if (self.transaction.direction == HITransactionDirectionIncoming) {
        self.targetAddressLabel.stringValue =
            NSLocalizedString(@"Received with address:",
                              @"Transaction target address label for incoming transactions");
    } else {
        self.targetAddressLabel.stringValue =
            NSLocalizedString(@"Target address:",
                              @"Transaction target address label for outgoing transactions");
    }

    self.targetAddressField.stringValue = self.transaction.targetAddress ?:
                                          [[BCClient sharedClient] walletHash] ?:
                                          @"?";
}

- (NSString *)transactionStatus {
    switch (self.transaction.status) {
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

- (IBAction)showOnBlockchainInfoClicked:(id)sender {
    NSString *url = [NSString stringWithFormat:@"https://blockchain.info/tx/%@", self.transaction.id];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];

    [sender setState:NSOnState];
}

- (void)popoverDidClose:(NSNotification *)notification {
    id<HITransactionPopoverDelegate> delegate = self.delegate;

    if (delegate && [delegate respondsToSelector:@selector(transactionPopoverDidClose:)]) {
        [delegate transactionPopoverDidClose:self];
    }
}

@end
