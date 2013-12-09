//
//  NSColor+NativeColor.m
//  Hive
//
//  Created by Bazyli Zygan on 11.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "NSColor+Hive.h"

@implementation NSColor (Hive)

+ (NSColor *)hiWindowBackgroundColor {
    return [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
}

- (CGColorRef)hiNativeColor {
    const NSInteger numberOfComponents = [self numberOfComponents];
    CGFloat components[numberOfComponents];
    CGColorSpaceRef colorSpace = [[self colorSpace] CGColorSpace];
    
    [self getComponents:(CGFloat *)&components];
    
    return (CGColorRef)CGColorCreate(colorSpace, components);
}

@end
