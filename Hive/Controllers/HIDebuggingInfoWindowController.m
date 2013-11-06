//
//  HIDebuggingInfoWindowController.m
//  Hive
//
//  Created by Jakub Suder on 29.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <BitcoinJKit/BitcoinJKit.h>
#import "HIDebuggingInfoWindowController.h"

@implementation HIDebuggingInfoWindowController

- (id)init
{
    return [self initWithWindowNibName:@"HIDebuggingInfoWindowController"];
}

- (void)showWindow:(id)sender
{
    [super showWindow:sender];
    [self updateInfo];
}

- (void)updateInfo
{
    NSMutableString *info = [[NSMutableString alloc] init];
    HIBitcoinManager *bitcoin = [HIBitcoinManager defaultManager];

    [info appendFormat:@"## Basic info\n\n"];
    [info appendFormat:@"Wallet address: %@\n", bitcoin.walletAddress];
    [info appendFormat:@"Wallet balance: %lld\n", bitcoin.balance];

    [info appendFormat:@"\n## Transaction list\n\n"];

    [info appendFormat:@"%@", bitcoin.allTransactions];

    self.textView.string = info;
}

@end
