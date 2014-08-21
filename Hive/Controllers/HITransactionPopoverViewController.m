//
//  HITransactionPopoverViewController.m
//  Hive
//
//  Created by Jakub Suder on 11/08/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HITransaction.h"
#import "HITransactionPopoverViewController.h"

@interface HITransactionPopoverViewController ()

@property (weak) IBOutlet NSTextField *transactionIdField;
@property (weak) IBOutlet NSTextField *statusField;
@property (weak) IBOutlet NSTextField *confirmationsField;

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
    popover.behavior = NSPopoverBehaviorSemitransient;
    return popover;
}

- (void)awakeFromNib {
    if (self.transaction.id) {
        self.transactionData = [[BCClient sharedClient] transactionDefinitionWithHash:self.transaction.id];
    }

    self.transactionIdField.stringValue = self.transaction.id ?: @"?";
    self.confirmationsField.stringValue = [self.transactionData[@"confirmations"] description] ?: @"";
    self.statusField.stringValue = [self transactionStatus];
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

- (IBAction)showOnBlockchainInfoClicked:(id)sender {
    NSString *url = [NSString stringWithFormat:@"https://blockchain.info/tx/%@", self.transaction.id];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];

    [sender setState:NSOnState];
}

@end
