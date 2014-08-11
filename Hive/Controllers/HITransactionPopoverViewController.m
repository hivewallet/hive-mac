//
//  HITransactionPopoverViewController.m
//  Hive
//
//  Created by Jakub Suder on 11/08/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HITransaction.h"
#import "HITransactionPopoverViewController.h"

@interface HITransactionPopoverViewController ()

@property (weak) IBOutlet NSTextField *transactionIdField;

@property (strong) HITransaction *transaction;

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
    self.transactionIdField.stringValue = self.transaction.id ?: @"?";
}

@end
