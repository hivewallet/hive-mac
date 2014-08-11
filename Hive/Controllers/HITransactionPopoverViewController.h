//
//  HITransactionPopoverViewController.h
//  Hive
//
//  Created by Jakub Suder on 11/08/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HITransactionPopoverViewController : NSViewController

- (instancetype)initWithTransaction:(HITransaction *)transaction;
- (NSPopover *)createPopover;

@end
