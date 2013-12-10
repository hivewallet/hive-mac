//
//  HIPasswordInputViewController.m
//  Hive
//
//  Created by Nikolaj Schumacher on 2013-12-09.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIPasswordInputViewController.h"

#import "HIPasswordHolder.h"

/*
 We don't want the password sitting there while the user walks away.
 */
static const NSTimeInterval IDLE_RESET_DELAY = 30.0;

@interface HIPasswordInputViewController ()<NSTextFieldDelegate>

@property (nonatomic, strong) IBOutlet NSSecureTextField *passwordField;

@property (nonatomic, strong) NSTimer *resetTimer;
@property (nonatomic, assign) BOOL submitButtonEnabled;

@end

@implementation HIPasswordInputViewController

- (id)init {
    return [self initWithNibName:[self className] bundle:nil];
}

- (IBAction)submit:(id)sender {
    HIPasswordHolder *passwordHolder = [[HIPasswordHolder alloc] initWithString:self.passwordField.stringValue];
    @try {
        [self resetInput];
        if (self.onSubmit) {
            self.onSubmit(passwordHolder);
        }
    } @finally {
        [passwordHolder clear];
    }
}

- (void)resetInput {
    self.passwordField.stringValue = @"";
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)notification {
    self.submitButtonEnabled = self.passwordField.stringValue.length > 0;
    [self startHIdleResetDelay];
}

- (void)startHIdleResetDelay {
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(resetInput)
                                               object:nil];
    [self performSelector:@selector(resetInput)
               withObject:nil
               afterDelay:IDLE_RESET_DELAY];
}

@end
