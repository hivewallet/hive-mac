#import "HIPaddedSecureTextFieldCell.h"

static const double EDIT_OFFSET = -2;

@implementation HIPaddedSecureTextFieldCell

- (NSRect)drawingRectForBounds:(NSRect)theRect {
    NSRect drawingRect = [super drawingRectForBounds:theRect];
    NSSize textSize = [self cellSizeForBounds:theRect];

    float delta = drawingRect.size.height - textSize.height;
    drawingRect.size.height -= delta;
    drawingRect.origin.y += delta * .5;

    return drawingRect;
}

- (void)selectWithFrame:(NSRect)rect
                 inView:(NSView *)controlView
                 editor:(NSText *)textObj
               delegate:(id)anObject
                  start:(NSInteger)selStart
                 length:(NSInteger)selLength {

    rect = [self drawingRectForBounds:rect];
    rect.origin.x += EDIT_OFFSET;
    rect.size.width -= 2 * EDIT_OFFSET;
    [super selectWithFrame:rect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)editWithFrame:(NSRect)aRect
               inView:(NSView *)controlView
               editor:(NSText *)textObj
             delegate:(id)anObject
                event:(NSEvent *)theEvent {

    aRect = [self drawingRectForBounds:aRect];
    [super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
}

@end
