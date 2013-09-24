//
//  HIDeleteButtonCell.m
//  Hive
//
//  Created by Bazyli Zygan on 17.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIDeleteButtonCell.h"
#import "NSColor+NativeColor.h"

@implementation HIDeleteButtonCell

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
    NSBezierPath *p = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:5 yRadius:5];
    NSBezierPath *sP = [NSBezierPath bezierPath];
    p.lineWidth = 0.5;
    if (![[NSColor blackColor] respondsToSelector:@selector(CGColor)])
        controlView.layer.shadowOffset = NSMakeSize(0, -1);
    [sP moveToPoint:NSMakePoint(1, 3)];
    [sP curveToPoint:NSMakePoint(5, 1)
       controlPoint1:NSMakePoint(5, 1)
       controlPoint2:NSMakePoint(5, 1)];
    
    [sP lineToPoint:NSMakePoint(frame.size.width-5, 1)];
    [sP curveToPoint:NSMakePoint(frame.size.width-1, 3)
       controlPoint1:NSMakePoint(frame.size.width-5, 1)
       controlPoint2:NSMakePoint(frame.size.width-5, 1)];
    
    if (self.isHighlighted)
    {
        [RGB(167, 31, 39) setFill];
        [p fill];
        [[NSColor colorWithCalibratedWhite:0 alpha:0.35] set];
        controlView.layer.shadowColor = [[NSColor whiteColor] NativeColor];
    }
    else
    {
        NSGradient *g = [[NSGradient alloc] initWithColors:@[RGB(248,85,94), RGB(167, 31, 39)]];
        [g drawInBezierPath:p angle:90];
        [RGB(255, 255, 255) set];
        controlView.layer.shadowColor = [[NSColor blackColor] NativeColor];
    }
    [sP stroke];
    
    
    [RGB(167, 31, 39) set];
    [p stroke];
    
    
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
    NSShadow *sh = [[NSShadow alloc] init];
    sh.shadowColor = [NSColor blackColor];
    sh.shadowOffset = NSMakeSize(0, -1);
    sh.shadowBlurRadius = 1;
    
    NSDictionary *attrs = @{
                            NSFontAttributeName: [NSFont fontWithName:@"Helvetica-Bold" size:13],
                            NSForegroundColorAttributeName: [NSColor whiteColor],
                            NSShadowAttributeName: sh
                            };
    
    
    NSSize size = [self.title sizeWithAttributes:attrs];
    NSRect drawRect = NSMakeRect(frame.origin.x + (frame.size.width - size.width) / 2.0,
                                 frame.origin.y - 1 + (frame.size.height - size.height) / 2.0, size.width, size.height);
    [self.title drawAtPoint:drawRect.origin withAttributes:attrs];
    
    return drawRect;
}
@end
