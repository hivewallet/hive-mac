//
//  HIMainWindowController.h
//  Hive
//
//  Created by Bazyli Zygan on 12.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <INAppStoreWindow/INAppStoreWindow.h>
#import "HILockScreenView.h"
#import "HIPasswordInputViewController.h"
#import "HISidebarController.h"
#import "HIViewController.h"

extern NSString * const LockScreenEnabledDefaultsKey;

/*
 Manages the main Hive window, switching between tabs using sidebar buttons etc.
 */

@interface HIMainWindowController : NSWindowController <HISidebarControllerDelegate>

@property (strong) IBOutlet NSView *contentView;
@property (strong) IBOutlet HILockScreenView *overlayView;
@property (strong) IBOutlet NSButton *sendButton;
@property (strong) IBOutlet HIPasswordInputViewController *passwordInputViewController;
@property (strong) IBOutlet HISidebarController *sidebarController;
@property (strong) IBOutlet NSView *networkErrorView;

- (void)switchToPanel:(Class)panelClass;
- (void)lockWalletAnimated:(BOOL)animated;
- (void)lockApplicationAnimated:(BOOL)animated;
- (void)unlockApplicationAnimated:(BOOL)animated;

@end
