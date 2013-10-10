//
//  HIProfileTabBarController.h
//  Hive
//
//  Created by Jakub Suder on 06.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HIProfileTabBarController;

/*
 Notifies the delegate (HIProfileViewController) that a tab was selected.
 */

@protocol HIProfileTabBarControllerDelegate <NSObject>

@optional
- (void)controller:(HIProfileTabBarController *)controller switchedToTabIndex:(NSInteger)index;

@end


/*
 Manages the horizontal tab bar on a contact page that selects between contact transactions list and contact info.
 */

@interface HIProfileTabBarController : NSViewController

@property (nonatomic, strong) IBOutlet id<HIProfileTabBarControllerDelegate> tabDelegate;

- (void)selectTabAtIndex:(NSUInteger)selectedIndex;

@end
