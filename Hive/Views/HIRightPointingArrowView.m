//
//  HIRightPointingArrowView.m
//  Hive
//
//  Created by Jakub Suder on 12.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIRightPointingArrowView.h"
#import "NSColor+Hive.h"

@implementation HIRightPointingArrowView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        _strokeColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.75];
        _strokeWidth = 0.5;

        self.layer.shadowColor = [[NSColor whiteColor] hiNativeColor];
        self.layer.shadowOffset = NSMakeSize(1, -1);
        self.layer.shadowOpacity = 1.0;
        self.layer.shadowRadius = 0.0;
    }

    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [_strokeColor setStroke];

    NSBezierPath *line = [NSBezierPath bezierPath];
    line.lineWidth = _strokeWidth;

    [line moveToPoint:NSMakePoint(0, 0)];
    [line lineToPoint:NSMakePoint(self.bounds.size.width - 1, self.bounds.size.height / 2)];
    [line lineToPoint:NSMakePoint(0, self.bounds.size.height - 1)];
    [line stroke];
}

@end
