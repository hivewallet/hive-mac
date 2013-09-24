//
//  HISidebarController.h
//  Hive
//
//  Created by Jakub Suder on 30.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HIViewController;

extern const NSInteger SidebarButtonWidth;
extern const NSInteger SidebarButtonHeight;

@protocol HISidebarControllerDelegate

- (void)sidebarDidSelectController:(HIViewController *)selectedController again:(BOOL)again;

@end

@interface HISidebarController : NSObject

@property (strong, nonatomic) IBOutlet NSView *view;
@property (nonatomic) NSUInteger selectedTabIndex;
@property (assign, nonatomic) IBOutlet id<HISidebarControllerDelegate> delegate;

- (void)addViewController:(HIViewController *)controller;

@end
