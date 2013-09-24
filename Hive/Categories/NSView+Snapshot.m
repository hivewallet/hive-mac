//
//  NSView+Snapshot.m
//  Hive
//
//  Created by Bazyli Zygan on 21.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "NSView+Snapshot.h"

@implementation NSView (Snapshot)

- (NSImage *)snapshot
{
    
    NSSize imgSize = self.bounds.size;
    
    NSBitmapImageRep * bir = [self bitmapImageRepForCachingDisplayInRect:[self bounds]];
    [bir setSize:imgSize];
    
    [self cacheDisplayInRect:[self bounds] toBitmapImageRep:bir];
    
    NSImage* image = [[NSImage alloc] initWithSize:imgSize];
    [image addRepresentation:bir];
    
    return image;
}
@end
