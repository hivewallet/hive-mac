//
//  HISeparatorView.m
//  Hive
//
//  Created by Bazyli Zygan on 02.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HISeparatorView.h"
#import "NSColor+NativeColor.h"

@implementation HISeparatorView

- (void)awakeFromNib
{
    self.wantsLayer = YES;
    self.layer.backgroundColor = [RGB(211,211,211) NativeColor];
}


@end
