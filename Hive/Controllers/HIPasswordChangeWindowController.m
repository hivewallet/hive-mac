//
//  HIPasswordChangeWindowController.m
//  Hive
//
//  Created by Nikolaj Schumacher on 2013-12-17.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HIPasswordChangeWindowController.h"
#import "HIPasswordCreationInputHandler.h"
#import "HIPasswordHolder.h"
#import "NSWindow+HIShake.h"

/*
 We don't want the password sitting there while the user walks away.
 */
static const NSTimeInterval IDLE_RESET_DELAY = 30.0;

@interface HIPasswordChangeWindowController ()

@property (nonatomic, weak) IBOutlet NSSecureTextField *passwordField;
@property (nonatomic, weak) IBOutlet NSSecureTextField *updatedPasswordField;
@property (nonatomic, weak) IBOutlet NSSecureTextField *repeatedPasswordField;

// top-level objects
@property (nonatomic, strong) IBOutlet HIPasswordCreationInputHandler *passwordCreationInputHandler;

@property (nonatomic, assign) BOOL submitButtonEnabled;

@end

@implementation HIPasswordChangeWindowController

- (instancetype)init {
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
    /*[self.passwordCreationInputHandler finishWithPasswordHolder:^(HIPasswordHolder *changedPasswordHolder) {
        HIPasswordHolder *passwordHolder =
            self.passwordField.isEnabled ?
                [[HIPasswordHolder alloc] initWithString:self.passwordField.stringValue] : nil;

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
        }

    }];*/
}

- (void)resetInput {
    self.passwordField.stringValue = @"";
    [self.passwordCreationInputHandler resetInput];
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
        } else if (self.submitButtonEnabled) {
            [self submit:control];
        }

        return YES;
    } else {
        return NO;
    }
}

- (void)controlTextDidChange:(NSNotification *)notification {
    self.submitButtonEnabled = (self.updatedPasswordField.stringValue.length > 0 &&
                                self.repeatedPasswordField.stringValue.length > 0);

    [self.passwordCreationInputHandler textDidChangeInTextField:notification.object];

    [self updateIdleResetDelay];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    [self.passwordCreationInputHandler editingDidEnd];
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
