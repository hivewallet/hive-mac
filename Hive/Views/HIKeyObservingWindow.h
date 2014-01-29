//
//  HIKeyObservingWindow.h
//  Hive
//
//  Created by Jakub Suder on 29/01/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol HIKeyObservingWindowDelegate

- (void)keyFlagsChanged:(NSUInteger)flags inWindow:(NSWindow *)window;

@end


/*
 A window that notifies its delegate when key flags are changed.
 */

@interface HIKeyObservingWindow : NSWindow

@end
