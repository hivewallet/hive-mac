//
//  HIBox.m
//  Hive
//
//  Created by Bazyli Zygan on 05.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIBox.h"

@implementation HIBox

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath *p = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:5 yRadius:5];
    
    [[NSColor whiteColor] setFill];
    [p fill];
    [RGB(195,195,195) set];
    [p stroke];
    
    NSBezierPath *sP = [NSBezierPath bezierPath];
    NSRect frame = self.bounds;
    [sP moveToPoint:NSMakePoint(1, frame.size.height-3)];
    [sP curveToPoint:NSMakePoint(5, frame.size.height-1) controlPoint1:NSMakePoint(5, frame.size.height-1) controlPoint2:NSMakePoint(5, frame.size.height-1)];
    [sP lineToPoint:NSMakePoint(frame.size.width-5, frame.size.height-1)];
    [sP curveToPoint:NSMakePoint(frame.size.width-1, frame.size.height-3) controlPoint1:NSMakePoint(frame.size.width-5, frame.size.height-1) controlPoint2:NSMakePoint(frame.size.width-5, frame.size.height-1)];
    [[NSColor colorWithCalibratedWhite:0 alpha:0.35] set];
    [sP stroke];
}

@end
