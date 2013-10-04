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

    NSRect inset = NSInsetRect(frame, 1.0, 1.0);

    NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:inset];
    [path addClip];
    
    [self.image drawInRect:inset
                  fromRect:NSZeroRect
                 operation:NSCompositeSourceOver
                  fraction:1.0];

    [NSGraphicsContext restoreGraphicsState];
}

@end
