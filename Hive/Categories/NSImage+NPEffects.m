//
//  NSImage+NPEffects.m
//  Hive
//
//  Created by Bazyli Zygan on 12.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "NSImage+NPEffects.h"

@implementation NSImage (NPEffects)

- (NSImage *)darkImage
{
    NSImage *offImg = [self copy];
    
    [offImg setTemplate:YES];
    [offImg lockFocus];
    
    NSGradient *g = [[NSGradient alloc] initWithStartingColor:[NSColor blueColor] endingColor:[NSColor blackColor]];
    
    NSGraphicsContext* ctx = [NSGraphicsContext currentContext];
    [ctx saveGraphicsState];
    [ctx setCompositingOperation:NSCompositeSourceAtop];
    [[NSColor blackColor] setFill];
//    NSRectFill(NSMakeRect(0, 0, offImg.size.width, offImg.size.height));
    [g drawInRect:NSMakeRect(0, 0, self.size.width, self.size.height) angle:-90];
    [ctx restoreGraphicsState];
    [offImg unlockFocus];
    
    
    return offImg;
}

@end
