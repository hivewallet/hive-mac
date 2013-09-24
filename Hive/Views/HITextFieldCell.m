//
//  HITextFieldCell.m
//  Hive
//
//  Created by Bazyli Zygan on 15.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HITextFieldCell.h"
#import "HITextField.h"
@implementation HITextFieldCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [super drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
//    [[NSColor clearColor] setFill];
//    NSRectFill(cellFrame);
//    [super drawWithFrame:cellFrame inView:controlView];
    HITextField *tf = nil;
    if ([controlView isKindOfClass:[HITextField class]])
        tf = (HITextField *)controlView;
    
    if (self.stringValue.length == 0 && !tf.isFocused)
    {
        // We should draw placeholder here, so
        [self.placeholderString drawAtPoint:NSZeroPoint withAttributes:@{NSFontAttributeName: self.font, NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:0 alpha:0.6]}];
        
    }
    else if (!tf.isFocused)
    {
        [super drawWithFrame:cellFrame inView:controlView];
    }

}

@end
