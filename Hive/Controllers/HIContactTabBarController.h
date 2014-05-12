//
//  HIContactTabBarController.h
//  Hive
//
//  Created by Jakub Suder on 06.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

@class HIContactTabBarController;

/*
 Notifies the delegate (HIContactViewController) that a tab was selected.
 */

@protocol HIProfileTabBarControllerDelegate <NSObject>

@optional
- (void)controller:(HIContactTabBarController *)controller switchedToTabIndex:(NSInteger)index;

@end


/*
 Manages the horizontal tab bar on a contact page that selects between contact transactions list and contact info.
 */

@interface HIContactTabBarController : NSViewController

@property (nonatomic, strong) IBOutlet id<HIProfileTabBarControllerDelegate> tabDelegate;

- (void)selectTabAtIndex:(NSUInteger)selectedIndex;

@end
