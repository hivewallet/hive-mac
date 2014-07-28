//
//  HILockScreenViewController.m
//  Hive
//
//  Created by Jakub Suder on 28/03/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import <BitcoinJKit/HIBitcoinManager.h>
#import "HILockScreenViewController.h"
#import "HIPasswordHolder.h"
#import "HIPasswordInputViewController.h"
#import "NSWindow+HIShake.h"

NSString * const LockScreenEnabledDefaultsKey = @"LockScreenEnabled";
NSString * const LockScreenWillAppearNotification = @"LockScreenWillAppearNotification";
NSString * const LockScreenDidAppearNotification = @"LockScreenDidAppearNotification";
NSString * const LockScreenWillDisappearNotification = @"LockScreenWillDisappearNotification";
NSString * const LockScreenDidDisappearNotification = @"LockScreenDidDisappearNotification";


@interface HILockScreenViewController ()

@property (nonatomic, strong) IBOutlet HIPasswordInputViewController *passwordInputViewController;
@property (nonatomic, strong) IBOutlet NSTextField *passwordField;
@property (nonatomic, strong) IBOutlet NSButton *submitButton;
@property (nonatomic, strong) IBOutlet NSButton *dontShowAgainField;
@property (nonatomic, strong) IBOutlet NSView *container;

@end


@implementation HILockScreenViewController

- (void)awakeFromNib {
    if (!self.passwordInputViewController) {
        // wait until your own nib loads
        return;
    }

    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(onSleep)
                                                               name:NSWorkspaceWillSleepNotification
                                                             object:nil];

    __unsafe_unretained typeof(self) lwc = self;
    self.passwordInputViewController.onSubmit = ^(HIPasswordHolder *passwordHolder) {
        [lwc onPasswordEntered:passwordHolder];
    };

    [self setInitialState];
}

- (void)setInitialState {
    if ([[HIBitcoinManager defaultManager] isWalletEncrypted] && [self isLockScreenEnabled]) {
        [self showLockScreenAnimated:NO];
    } else {
        [self hideLockScreenAnimated:NO];
    }
}

- (BOOL)isLockScreenEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:LockScreenEnabledDefaultsKey];
}

- (void)setLockScreenEnabled:(BOOL)enabled {
    return [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:LockScreenEnabledDefaultsKey];
}

- (void)lockWalletAnimated:(BOOL)animated {
    if ([[HIBitcoinManager defaultManager] isWalletEncrypted]) {
        self.dontShowAgainField.state = NSOffState;

        [self showLockScreenAnimated:animated];
        [self setLockScreenEnabled:YES];
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText:@"You need to set a wallet password first."
                                         defaultButton:@"Ok"
                                       alternateButton:nil otherButton:nil
                             informativeTextWithFormat:@"Open the \"Wallet\" menu and select \"Change Password\" "
                                                       @"to encrypt your wallet with a password."];
        [alert runModal];
    }
}

- (void)showLockScreenAnimated:(BOOL)animated {
    self.view.frame = self.container.bounds;

    [[NSNotificationCenter defaultCenter] postNotificationName:LockScreenWillAppearNotification object:self];

    if (animated) {
        [self.view setAlphaValue:0.0];
        [self.container addSubview:self.view];

        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [self.view.animator setAlphaValue:1.0];
        } completionHandler:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:LockScreenDidAppearNotification object:self];
        }];
    } else {
        [self.view setAlphaValue:1.0];
        [self.container addSubview:self.view];

        [[NSNotificationCenter defaultCenter] postNotificationName:LockScreenDidAppearNotification object:self];
    }

    [self.container.window makeFirstResponder:self.passwordField];
    [[NSApp delegate] setApplicationLocked:YES];
}

- (void)hideLockScreenAnimated:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] postNotificationName:LockScreenWillDisappearNotification object:self];

    if (animated) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            [self.view.animator setAlphaValue:0.0];
        } completionHandler:^{
            [self.view removeFromSuperview];
            [[NSNotificationCenter defaultCenter] postNotificationName:LockScreenDidDisappearNotification object:self];
        }];
    } else {
        [self.view setAlphaValue:0.0];
        [self.view removeFromSuperview];

        [[NSNotificationCenter defaultCenter] postNotificationName:LockScreenDidDisappearNotification object:self];
    }

    [self.container.window makeFirstResponder:nil];
    [[NSApp delegate] setApplicationLocked:NO];
}

- (void)onSleep {
    if ([self isLockScreenEnabled]) {
        [self lockWalletAnimated:NO];
    }
}

- (void)onPasswordEntered:(HIPasswordHolder *)passwordHolder {
    if ([[HIBitcoinManager defaultManager] isPasswordCorrect:passwordHolder.data]) {
        [self hideLockScreenAnimated:YES];
        [self setLockScreenEnabled:(self.dontShowAgainField.state == NSOffState)];
    } else {
        [self.container.window hiShake];
    }
}

- (void)dealloc {
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}

@end
