//
//  HIProfileTabBarController.h
//  Hive
//
//  Created by Jakub Suder on 06.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HIProfileTabBarController;

@protocol HIProfileTabBarControllerDelegate <NSObject>

@optional
- (void)controller:(HIProfileTabBarController *)controller switchedToTabIndex:(NSInteger)index;

@end



@interface HIProfileTabBarController : NSViewController

@property (nonatomic, strong) IBOutlet id<HIProfileTabBarControllerDelegate> tabDelegate;

@end
