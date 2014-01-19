//
//  HIButtonCell.m
//  Hive
//
//  Created by Bazyli Zygan on 05.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIDoneButtonCell.h"

@implementation HIDoneButtonCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.cornerRadius = 5.0;
    self.hasShadow = YES;
    self.font = [NSFont fontWithName:@"Helvetica-Bold" size:13];
}

- (NSSize)cellSize {
    CGSize size = [super cellSize];
    size.height = MAX(28, size.height);
    return size;
}


@end
