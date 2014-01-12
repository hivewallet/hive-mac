#import "HIDraggableButton.h"

@implementation HIDraggableButton

- (void)mouseDown:(NSEvent *)theEvent {
    if (self.draggable) {
        [self.nextResponder mouseDown:theEvent];
    } else {
        [super mouseDown:theEvent];
    }
}

- (void)mouseUp:(NSEvent *)theEvent {
    if (self.draggable) {
        [self.nextResponder mouseUp:theEvent];
    } else {
        [super mouseUp:theEvent];
    }
}


@end
