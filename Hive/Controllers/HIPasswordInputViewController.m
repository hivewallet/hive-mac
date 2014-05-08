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

@property (nonatomic, assign) BOOL submitButtonEnabled;
@property (nonatomic, strong) IBOutlet NSSecureTextField *passwordField;

@end

@implementation HIPasswordInputViewController

- (instancetype)init {
    return [self initWithNibName:[self className] bundle:nil];
}

- (IBAction)submit:(id)sender {
    @autoreleasepool {
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
}

- (void)resetInput {
    self.passwordField.stringValue = @"";
    [self updateIdleResetDelay];
}

#pragma mark - NSTextFieldDelegate

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if (commandSelector == @selector(insertNewline:)) {
        [self submit:control];
        return YES;
    } else {
        return NO;
    }
}


- (void)controlTextDidChange:(NSNotification *)notification {
    self.submitButtonEnabled = self.passwordField.stringValue.length > 0;
    [self updateIdleResetDelay];
}

- (void)updateIdleResetDelay {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetInput) object:nil];
    if (self.passwordField.stringValue.length > 0) {
        [self performSelector:@selector(resetInput)
                   withObject:nil
                   afterDelay:IDLE_RESET_DELAY];
    }
}

@end
