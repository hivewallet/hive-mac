//
//  HIViewController.h
//  Hive
//
//  Created by Bazyli Zygan on 12.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

@class HIMainWindowController;
@class HINavigationController;


/*
 A base class for all view controllers of views that go into the right panel of the main window.
 */

@interface HIViewController : NSViewController

@property (nonatomic, strong) NSString *iconName;
@property (nonatomic, assign) NSUInteger badgeNumber;
@property (nonatomic, assign) HINavigationController *navigationController;
@property (nonatomic, readonly, getter = titleBarView) NSView *titleBarView;
@property (nonatomic, readonly, getter = rightNavigationView) NSView *rightNavigationView;

- (void)viewWillAppear;
- (void)viewWillDisappear;
- (void)applicationReturnedToForeground;
- (void)viewWasSelectedFromTabBar;
- (void)viewWasSelectedFromTabBarAgain;
- (void)requestPopFromStackWithAction:(void (^)())action;

@end
