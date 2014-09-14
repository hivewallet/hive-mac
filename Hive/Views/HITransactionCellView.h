//
//  HITransactionCellView.h
//  Hive
//
//  Created by Jakub Suder on 06.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

/*
 Table cell view used on the transactions list, shows details of a specific transaction.
 */

@interface HITransactionCellView : NSTableCellView

@property (weak, nonatomic, readonly) NSTextField *dateLabel;
@property (weak, nonatomic, readonly) NSImageView *directionMark;
@property (weak, nonatomic, readonly) NSTextField *pendingLabel;

@end
