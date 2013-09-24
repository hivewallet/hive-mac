//
//  HIImageCell.m
//  Hive
//
//  Created by Bazyli Zygan on 20.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIImageCell.h"

@implementation HIImageCell

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)controlView
{
    [NSGraphicsContext saveGraphicsState];
    
    NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(frame.origin.x+1, frame.origin.y+1, frame.size.width-2, frame.size.height-2)];
    
//    [[NSColor colorWithCalibratedRed:97.0/255.0 green:186.0/255.0 blue:108.0/255.0 alpha:1] setFill];
//    [path fill];
    [path addClip];
    
    [self.image drawInRect:NSMakeRect(frame.origin.x+1, frame.origin.y+1, frame.size.width-2, frame.size.width-2)
             fromRect:NSZeroRect
            operation:NSCompositeSourceOver
             fraction:1.0];
    
    [NSGraphicsContext restoreGraphicsState];
}
@end
