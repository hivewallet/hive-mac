//
//  HITransactionCellView.h
//  Hive
//
//  Created by Jakub Suder on 06.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 Table cell view used on the transactions list, shows details of a specific transaction.
 */

@interface HITransactionCellView : NSTableCellView

@property (strong, nonatomic) IBOutlet NSTextField *dateLabel;
@property (strong, nonatomic) IBOutlet NSImageView *directionMark;
@property (strong, nonatomic) IBOutlet NSTextField *pendingLabel;

@end
