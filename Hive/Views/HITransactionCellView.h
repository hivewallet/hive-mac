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

@property (nonatomic, weak, readonly) NSTextField *dateLabel;
@property (nonatomic, weak, readonly) NSImageView *directionMark;
@property (nonatomic, weak, readonly) NSTextField *pendingLabel;

@end
