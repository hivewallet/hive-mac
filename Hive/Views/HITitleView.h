//
//  HITitleView.h
//  Hive
//
//  Created by Bazyli Zygan on 02.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HITitleView;

/*
 Notifies the delegate (HINavigationController) that the "back" button was clicked in the breadcrumbs bar
 and the current top view should be popped from the stack.
 */

@protocol HITitleViewDelegate <NSObject>

- (void)requestedPop:(HITitleView *)titleView;

@end


/*
 Implements the breadcrumbs view for the window title bar. Maintains a stack of titles, handles pushing and popping
 titles from the stack with proper animations.
 */

@interface HITitleView : NSView

@property (nonatomic, assign) id<HITitleViewDelegate> delegate;

- (void)pushTitle:(NSString *)title;
- (void)popToTitleAtPosition:(NSInteger)position;
- (void)updateTitleAtPosition:(NSInteger)position toValue:(NSString *)newTitle;

@end
