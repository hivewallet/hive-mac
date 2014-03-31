//
//  HILockScreenViewController.h
//  Hive
//
//  Created by Jakub Suder on 28/03/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HIPasswordInputViewController;

extern NSString * const LockScreenEnabledDefaultsKey;
extern NSString * const LockScreenWillAppearNotification;
extern NSString * const LockScreenDidAppearNotification;
extern NSString * const LockScreenWillDisappearNotification;
extern NSString * const LockScreenDidDisappearNotification;


/*
 Manages the overlay view that covers the main window when the wallet is locked on startup.
 */

@interface HILockScreenViewController : NSViewController

- (void)lockWalletAnimated:(BOOL)animated;

@end
