/*
 Button that doesn't prevent dragging (e.g. in the title).
 */
@interface HIDraggableButton : NSButton

@property (nonatomic, assign) BOOL draggable;

@end
