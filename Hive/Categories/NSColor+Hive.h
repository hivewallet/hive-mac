//
//  NSColor+NativeColor.h
//  Hive
//
//  Created by Bazyli Zygan on 11.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

@interface NSColor (Hive)

+ (NSColor *)hiWindowBackgroundColor;

- (CGColorRef)hiNativeColor;

@end
