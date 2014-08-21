//
//  NSView+Hive.m
//  Hive
//
//  Created by Jakub Suder on 21.08.2014.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "NSView+Hive.h"

@implementation NSView (Hive)

- (NSArray *)hiRemoveConstraintsMatchingSubviews:(BOOL (^)(NSArray *))viewsMatch {
    NSMutableArray *removed = [NSMutableArray new];

    [self.constraints enumerateObjectsUsingBlock:^(id constraint, NSUInteger idx, BOOL *stop) {
        NSMutableArray *views = [NSMutableArray new];

        if ([constraint firstItem]) {
            [views addObject:[constraint firstItem]];
        }

        if ([constraint secondItem]) {
            [views addObject:[constraint secondItem]];
        }

        if (viewsMatch(views)) {
            [self removeConstraint:constraint];
            [removed addObject:constraint];
        }
    }];
    
    return removed;
}

@end
