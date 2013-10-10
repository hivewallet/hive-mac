//
//  HIProfileTabView.m
//  Hive
//
//  Created by Jakub Suder on 05.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIProfileTabView.h"

@interface HIProfileTabView () {
    NSGradient *_gradient;
}

@end

@implementation HIProfileTabView

- (void)awakeFromNib
{
    _gradient = [[NSGradient alloc] initWithStartingColor:RGB(245, 245, 245)
                                              endingColor:RGB(238, 238, 238)];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        [self awakeFromNib];
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [_gradient drawInRect:self.bounds angle:270.0];
}

@end
