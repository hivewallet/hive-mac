//
//  HIKeyObservingWindow.m
//  Hive
//
//  Created by Jakub Suder on 29/01/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HIKeyObservingWindow.h"

@implementation HIKeyObservingWindow

- (void)sendEvent:(NSEvent *)event {
    if (event.type == NSFlagsChanged && [self.delegate conformsToProtocol:@protocol(HIKeyObservingWindowDelegate)]) {
        [(id<HIKeyObservingWindowDelegate>) self.delegate keyFlagsChanged:event.modifierFlags inWindow:self];
    }

    [super sendEvent:event];
}

@end
