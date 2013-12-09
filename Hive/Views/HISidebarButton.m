//
//  HISidebarButton.m
//  Hive
//
//  Created by Jakub Suder on 30.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HISidebarButton.h"

static NSString *InsetButtonImage = @"button__inset";

@implementation HISidebarButton

- (void)drawRect:(NSRect)dirtyRect {
    if (self.state == NSOnState) {
        NSImage *insetBackground = [NSImage imageNamed:InsetButtonImage];
        [insetBackground drawInRect:self.bounds
                           fromRect:NSMakeRect(0, 1, self.bounds.size.width, self.bounds.size.height)
                          operation:NSCompositeCopy
                           fraction:1.0
                     respectFlipped:YES
                              hints:nil];
    }

    [super drawRect:dirtyRect];
}

@end
