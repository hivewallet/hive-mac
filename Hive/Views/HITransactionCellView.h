//
//  HITransactionCellView.h
//  Hive
//
//  Created by Jakub Suder on 06.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HITransactionCellView : NSTableCellView

@property (strong, nonatomic) IBOutlet NSTextField *dateLabel;
@property (strong, nonatomic) IBOutlet NSImageView *directionMark;

@end
