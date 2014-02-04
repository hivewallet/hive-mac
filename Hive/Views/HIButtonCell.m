//
//  HIButtonCell.m
//  Hive
//
//  Created by Bazyli Zygan on 05.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIButtonCell.h"
#import "NSColor+Hive.h"

static const float PADDING_X = 12.0;
static const float PADDING_Y = 0.0;

@implementation HIButtonCell

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView {
    NSBezierPath *p = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:5 yRadius:5];
    if (self.isHighlighted) {
        NSBezierPath *sP = [NSBezierPath bezierPath];
        
        [sP moveToPoint:NSMakePoint(1, 3)];
        [sP curveToPoint:NSMakePoint(5, 1) controlPoint1:NSMakePoint(5, 1) controlPoint2:NSMakePoint(5, 1)];
        [sP lineToPoint:NSMakePoint(frame.size.width-5, 1)];
        [sP curveToPoint:NSMakePoint(frame.size.width-1, 3) controlPoint1:NSMakePoint(frame.size.width-5, 1) controlPoint2:NSMakePoint(frame.size.width-5, 1)];
        [[NSColor colorWithCalibratedWhite:0 alpha:0.35] set];
        [RGB(237, 237, 237) setFill];
        [p fill];
        [sP stroke];
        
        controlView.layer.shadowColor = [[NSColor whiteColor] hiNativeColor];
    } else {
//        [RGB(183, 183, 183) set];
//        [sP stroke];
        
        NSGradient *g = [[NSGradient alloc] initWithColors:@[RGB(250,250,250), RGB(237, 237, 237)]];
        [g drawInBezierPath:p angle:90];
        controlView.layer.shadowColor = [[NSColor blackColor] hiNativeColor];
    }
    
    p.lineWidth = 0.5;    
    [RGB(128, 128, 128) set];
    [p stroke];
    
    
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView {
    NSShadow *sh = [[NSShadow alloc] init];
    sh.shadowColor = [NSColor whiteColor];
    sh.shadowOffset = NSMakeSize(0, -1);
    sh.shadowBlurRadius = 1;
    
    NSDictionary *attrs = @{NSFontAttributeName: [NSFont fontWithName:@"Helvetica" size:13], NSForegroundColorAttributeName: RGB(63, 63, 63), NSShadowAttributeName: sh};
    NSSize size = [self.title sizeWithAttributes:attrs];
    NSRect drawRect;
//    if (self.isHighlighted)
//    {
//        drawRect = NSMakeRect(frame.origin.x + (frame.size.width - size.width) / 2.0,
//                              frame.origin.y + 1 + (frame.size.height - size.height) / 2.0, size.width, size.height);
//    }
//    else
//    {
        drawRect = NSMakeRect(frame.origin.x + (frame.size.width - size.width) / 2.0,
                              frame.origin.y - 1 + (frame.size.height - size.height) / 2.0, size.width, size.height);        
//    }
    [self.title drawAtPoint:drawRect.origin withAttributes:attrs];
    
    return drawRect;
}

- (NSSize)cellSize {
    NSSize size = [super cellSize];
    size.width += 2 * PADDING_X;
    size.height += 2 * PADDING_Y;
    return size;
}

@end
