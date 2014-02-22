//
//  HIErrorBar.m
//  Hive
//
//  Created by Jakub Suder on 22/02/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HIErrorBar.h"

@implementation HIErrorBar {
    NSGradient *_gradient;
}

- (void)awakeFromNib {
    NSColor *red1 = [NSColor colorWithCalibratedHue:4.0/360 saturation:0.7 brightness:0.8 alpha:1.0];
    NSColor *red2 = [NSColor colorWithCalibratedHue:4.0/360 saturation:0.7 brightness:0.5 alpha:1.0];
    _gradient = [[NSGradient alloc] initWithStartingColor:red1 endingColor:red2];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self awakeFromNib];
    }

    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [_gradient drawInRect:self.bounds angle:270.0];
}

@end
