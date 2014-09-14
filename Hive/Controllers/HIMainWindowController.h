//
//  HIMainWindowController.h
//  Hive
//
//  Created by Bazyli Zygan on 12.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <INAppStoreWindow/INAppStoreWindow.h>
#import "HISidebarController.h"
#import "HIViewController.h"

@class HILockScreenViewController;


/*
 Manages the main Hive window, switching between tabs using sidebar buttons etc.
 */

@interface HIMainWindowController : NSWindowController <HISidebarControllerDelegate>

@property (nonatomic, strong, readonly) HILockScreenViewController *lockScreenController;

- (void)switchToPanel:(Class)panelClass;

@end
