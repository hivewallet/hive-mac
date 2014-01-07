//
//  HIPasswordChangeWindowController.m
//  Hive
//
//  Created by Nikolaj Schumacher on 2013-12-17.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIPasswordChangeWindowController.h"
#import "HIPasswordHolder.h"
#import "BCClient.h"
#import "NSWindow+HIShake.h"

#import <BitcoinJKit/HIBitcoinErrorCodes.h>

/*
 We don't want the password sitting there while the user walks away.
 */
static const NSTimeInterval IDLE_RESET_DELAY = 30.0;

@interface HIPasswordChangeWindowController ()

@property(nonatomic, strong) IBOutlet NSSecureTextField *passwordField;
@property(nonatomic, strong) IBOutlet NSSecureTextField *updatedPasswordField;
@property(nonatomic, strong) IBOutlet NSSecureTextField *repeatedPasswordField;

@property (nonatomic, assign) BOOL submitButtonEnabled;

@end

@implementation HIPasswordChangeWindowController

- (id)init {
    return [self initWithWindowNibName:[self className]];
}

- (IBAction)showWindow:(id)sender {
    [super showWindow:sender];

    [self resetInput];

    BOOL oldPasswordExists = [BCClient sharedClient].isWalletPasswordProtected;
    [self.passwordField setEnabled:oldPasswordExists];
    [(oldPasswordExists ? self.passwordField : self.updatedPasswordField) becomeFirstResponder];
}

- (IBAction)submit:(id)sender {
    if (![self arePasswordsEqual]) {
        [self updateValidation];
        [self.repeatedPasswordField becomeFirstResponder];
        return;
    }

    @autoreleasepool {
        HIPasswordHolder *passwordHolder =
            self.passwordField.stringValue.length > 0
                ? [[HIPasswordHolder alloc] initWithString:self.passwordField.stringValue] : nil;
        HIPasswordHolder *changedPasswordHolder =
            [[HIPasswordHolder alloc] initWithString:self.updatedPasswordField.stringValue];
        @try {
            NSError *error = nil;
            [[BCClient sharedClient] changeWalletPassword:passwordHolder
                                               toPassword:changedPasswordHolder
                                                    error:&error];
            if (error) {
                if (error.code == kHIBitcoinManagerWrongPassword) {
                    [self.window hiShake];
                    [self.passwordField becomeFirstResponder];
                } else {
                    [[NSAlert alertWithError:error] runModal];
                }
            } else {
                [self close];
            }
        } @finally {
            [passwordHolder clear];
            [changedPasswordHolder clear];
        }
    }
}

- (void)resetInput {
    self.passwordField.stringValue = @"";
    self.updatedPasswordField.stringValue = @"";
    self.repeatedPasswordField.stringValue = @"";
    [self updateIdleResetDelay];
}

- (void)close {
    [self resetInput];
    [super close];
}

#pragma mark - NSTextFieldDelegate

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if (commandSelector == @selector(insertNewline:)) {
        if (control == self.passwordField) {
            [self.updatedPasswordField becomeFirstResponder];
        } else if (control == self.updatedPasswordField) {
            [self.repeatedPasswordField becomeFirstResponder];
        } else {
            [self submit:control];
        }

        return YES;
    } else {
        return NO;
    }
}

- (void)controlTextDidChange:(NSNotification *)notification {
    // TODO: Do we impose password complexity rules?

    self.submitButtonEnabled = (!self.passwordField.isEnabled || self.passwordField.stringValue.length > 0)
        && self.updatedPasswordField.stringValue.length > 0;

    if (self.repeatedPasswordField != notification.object) {
        [self updateValidation];
    } else if ([self arePasswordsEqual]) {
        [self clearValidationProblems];
    }

    [self updateIdleResetDelay];
}

- (BOOL)arePasswordsEqual {
    return [self.updatedPasswordField.stringValue isEqualToString:self.repeatedPasswordField.stringValue];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    [self updateValidation];
}

- (void)updateValidation {
    if ([self arePasswordsEqual]) {
        [self clearValidationProblems];
    } else if (self.repeatedPasswordField.stringValue.length > 0) {
        [self setRepeatedPasswordBackgroundColor:[[NSColor redColor] colorWithAlphaComponent:0.25]];
    }
}

- (void)clearValidationProblems {
    [self setRepeatedPasswordBackgroundColor:[NSColor clearColor]];
}

- (void)setRepeatedPasswordBackgroundColor:(NSColor *)color {
    self.repeatedPasswordField.backgroundColor = color;

    // stupid Cocoa, y u no update the color
    [self.repeatedPasswordField setEditable:NO];
    [self.repeatedPasswordField setEditable:YES];
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
