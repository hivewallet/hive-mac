#import "HIGradientButtonCell.h"

#import "HIButtonWithSpinner.h"
#import "NSColor+Hive.h"

static const float PADDING_X = 5.0;
static const float PADDING_Y = 0.0;

@implementation HIGradientButtonCell

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView {
    double cornerRadius = self.cornerRadius;
    double midPoint = (self.cornerRadius - 1) * .5 + 1;

    NSBezierPath *p = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:cornerRadius yRadius:cornerRadius];
    NSBezierPath *sP = [NSBezierPath bezierPath];
    p.lineWidth = 0.5;

    [sP moveToPoint:NSMakePoint(1, midPoint)];
    [sP curveToPoint:NSMakePoint(cornerRadius, 1)
       controlPoint1:NSMakePoint(cornerRadius, 1)
       controlPoint2:NSMakePoint(cornerRadius, 1)];

    [sP lineToPoint:NSMakePoint(frame.size.width- cornerRadius, 1)];
    [sP curveToPoint:NSMakePoint(frame.size.width-1, midPoint)
       controlPoint1:NSMakePoint(frame.size.width- cornerRadius, 1)
       controlPoint2:NSMakePoint(frame.size.width- cornerRadius, 1)];

    if (self.isHighlighted) {
        [RGB(35, 116, 238) setFill];
        [p fill];
        [[NSColor colorWithCalibratedWhite:0 alpha:0.35] set];
        controlView.layer.shadowColor = [[NSColor whiteColor] hiNativeColor];
    } else {
        NSGradient *g = [[NSGradient alloc] initWithColors:@[RGB(54,185,251), RGB(35, 116, 238)]];
        [g drawInBezierPath:p angle:90];
        [RGB(255, 255, 255) set];
        controlView.layer.shadowColor = [[NSColor blackColor] hiNativeColor];
    }
    if (self.hasShadow) {
        [sP stroke];
    }


    [RGB(35, 116, 238) set];
    [p stroke];


}

- (NSDictionary *)drawingAttributes {
    NSShadow *sh = [[NSShadow alloc] init];
    sh.shadowColor = [NSColor blackColor];
    sh.shadowOffset = NSMakeSize(0, -1);
    sh.shadowBlurRadius = 1;

    NSDictionary *attrs = @{
        NSFontAttributeName: self.font,
        NSForegroundColorAttributeName: [NSColor whiteColor],
        NSShadowAttributeName: sh
    };
    return attrs;
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView {
    NSDictionary *attrs = [self drawingAttributes];

    if ([controlView respondsToSelector:@selector(titleFrame)]) {
        frame = (NSRect) [(id)controlView titleFrame];
    }

    NSSize size = [self.title sizeWithAttributes:attrs];
    NSRect drawRect = NSMakeRect(frame.origin.x + (frame.size.width - size.width) / 2.0,
        frame.origin.y + 1 + (frame.size.height - size.height) / 2.0, size.width, size.height);
    [self.title drawAtPoint:drawRect.origin withAttributes:attrs];

    return drawRect;
}

- (NSSize)cellSize {
    NSSize size = [self.title sizeWithAttributes:[self drawingAttributes]];
    size.width += 2 * PADDING_X;
    size.height += 2 * PADDING_Y;
    return size;
}

@end
