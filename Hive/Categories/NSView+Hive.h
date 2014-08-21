//
//  NSView+Hive.h
//  Hive
//
//  Created by Jakub Suder on 21.08.2014.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

@interface NSView (Hive)

- (NSArray *)hiRemoveConstraintsMatchingSubviews:(BOOL (^)(NSArray *))viewsMatch;

@end
