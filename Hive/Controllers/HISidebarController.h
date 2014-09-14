//
//  HISidebarController.h
//  Hive
//
//  Created by Jakub Suder on 30.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

@class HIViewController;

extern const NSInteger SidebarButtonWidth;
extern const NSInteger SidebarButtonHeight;

/*
 Notifies the delegate (HIMainWindowController) that a sidebar button was pressed and the view in the right panel
 should be replaced.
 */

@protocol HISidebarControllerDelegate

- (void)sidebarDidSelectController:(HIViewController *)selectedController again:(BOOL)again;

@end


/*
 Manages the left sidebar in the main window - selecting/unselecting buttons, notifying the main window etc.
 */

@interface HISidebarController : NSObject

@property (nonatomic, copy, readonly) NSArray *viewControllers;
@property (nonatomic, assign) BOOL enabled;

@property (nonatomic, weak, readonly) NSView *view;

- (void)addViewController:(HIViewController *)controller;
- (void)selectControllerAtIndex:(NSInteger)index;
- (void)unselectCurrentController;

- (void)applicationReturnedToForeground;

@end
