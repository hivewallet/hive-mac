//
//  NSColor+NativeColor.m
//  Hive
//
//  Created by Bazyli Zygan on 11.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "NSColor+NativeColor.h"

@implementation NSColor (NativeColor)

- (CGColorRef)NativeColor
{
    const NSInteger numberOfComponents = [self numberOfComponents];
    CGFloat components[numberOfComponents];
    CGColorSpaceRef colorSpace = [[self colorSpace] CGColorSpace];
    
    [self getComponents:(CGFloat *)&components];
    
    return (CGColorRef)CGColorCreate(colorSpace, components);
}

@end
