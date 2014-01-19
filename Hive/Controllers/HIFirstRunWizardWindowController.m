//
//  HIFirstRunWizardWindowController.m
//  Hive
//
//  Created by Nikolaj Schumacher on 2014-01-12.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HIFirstRunWizardWindowController.h"

#import "HIWizardWelcomeViewController.h"
#import "HIWizardCompletedViewController.h"
#import "HIWizardPasswordViewController.h"

@implementation HIFirstRunWizardWindowController

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        self.viewControllers = @[
            [HIWizardWelcomeViewController new],
            [HIWizardPasswordViewController new],
            [HIWizardCompletedViewController new],
        ];
    }
    return self;
}

@end
