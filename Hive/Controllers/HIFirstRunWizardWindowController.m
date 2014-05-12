//
//  HIFirstRunWizardWindowController.m
//  Hive
//
//  Created by Nikolaj Schumacher on 2014-01-12.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HIFirstRunWizardWindowController.h"

#import "HIWizardBackupViewController.h"
#import "HIWizardCompletedViewController.h"
#import "HIWizardPasswordViewController.h"
#import "HIWizardWelcomeViewController.h"

@implementation HIFirstRunWizardWindowController

- (instancetype)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        self.viewControllers = @[
            [HIWizardWelcomeViewController new],
            [HIWizardPasswordViewController new],
            [HIWizardBackupViewController new],
            [HIWizardCompletedViewController new],
        ];
    }
    return self;
}

- (void)keyFlagsChanged:(NSUInteger)flags inWindow:(NSWindow *)window {
    if ([self.currentViewController conformsToProtocol:@protocol(HIKeyObservingWindowDelegate)]) {
        [(id<HIKeyObservingWindowDelegate>) self.currentViewController keyFlagsChanged:flags inWindow:window];
    }
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    [self keyFlagsChanged:[NSEvent modifierFlags] inWindow:self.window];
}

@end
