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
    double cornerRadius = 5.0;
    double midPoint = (cornerRadius - 1.0) / 2 + 1.0;

    NSBezierPath *p = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:5 yRadius:5];

    NSColor *strokeColor = RGB(128, 128, 128);

    if (self.isHighlighted) {
        NSBezierPath *sP = [NSBezierPath bezierPath];
        
        [sP moveToPoint:NSMakePoint(1, midPoint)];
        [sP curveToPoint:NSMakePoint(cornerRadius, 1)
           controlPoint1:NSMakePoint(cornerRadius, 1)
           controlPoint2:NSMakePoint(cornerRadius, 1)];

        [sP lineToPoint:NSMakePoint(frame.size.width - cornerRadius, 1)];
        [sP curveToPoint:NSMakePoint(frame.size.width - 1, midPoint)
           controlPoint1:NSMakePoint(frame.size.width - cornerRadius, 1)
           controlPoint2:NSMakePoint(frame.size.width - cornerRadius, 1)];

        [[NSColor colorWithCalibratedWhite:0 alpha:0.35] set];
        [RGB(237, 237, 237) setFill];
        [p fill];
        [sP stroke];
        
        controlView.layer.shadowColor = [[NSColor whiteColor] hiNativeColor];
    } else {
        NSGradient *g = [[NSGradient alloc] initWithColors:@[RGB(250,250,250), RGB(237, 237, 237)]];
        [g drawInBezierPath:p angle:90];
        controlView.layer.shadowColor = [[NSColor blackColor] hiNativeColor];

        if (!self.isEnabled) {
            strokeColor = RGB(184, 203, 230);
        }
    }

    p.lineWidth = 0.5;
    [strokeColor set];
    [p stroke];
}

- (NSDictionary *)drawingAttributes {
    NSShadow *sh = [[NSShadow alloc] init];
    sh.shadowColor = [NSColor whiteColor];
    sh.shadowOffset = NSMakeSize(0, -1);
    sh.shadowBlurRadius = 1;

    return @{
      NSFontAttributeName: self.font,
      NSForegroundColorAttributeName: RGB(63, 63, 63),
      NSShadowAttributeName: sh
    };
}

- (NSDictionary *)disabledDrawingAttributes {
    return @{
      NSFontAttributeName: self.font,
      NSForegroundColorAttributeName: [NSColor grayColor],
    };
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView {
    NSDictionary *attrs = self.isEnabled ? [self drawingAttributes] : [self disabledDrawingAttributes];

    NSSize size = [self.title sizeWithAttributes:attrs];

    NSRect drawRect = NSMakeRect(frame.origin.x + (frame.size.width - size.width) / 2.0,
                                 frame.origin.y - 1 + (frame.size.height - size.height) / 2.0,
                                 size.width, size.height);

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
