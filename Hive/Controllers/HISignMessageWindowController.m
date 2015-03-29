//
//  HISignMessageWindowController.m
//  Hive
//
//  Created by Jakub Suder on 01.04.2014.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import <BitcoinJKit/BitcoinJKit.h>
#import <BitcoinJKit/HIBitcoinErrorCodes.h>
#import "BCClient.h"
#import "HIPasswordHolder.h"
#import "HIPasswordInputViewController.h"
#import "HISignMessageWindowController.h"
#import "NSWindow+HIShake.h"

@interface HISignMessageWindowController () <NSPopoverDelegate>

@property (nonatomic, weak) IBOutlet NSTextField *messageBox;
@property (nonatomic, weak) IBOutlet NSTextField *signatureBox;

@property (nonatomic, strong) HIPasswordInputViewController *passwordInputViewController;
@property (nonatomic, strong) NSPopover *passwordPopover;

@end


@implementation HISignMessageWindowController

- (instancetype)init {
    return [super initWithWindowNibName:self.className];
}

- (IBAction)cancelPressed:(id)sender {
    [self close];
}

- (IBAction)signPressed:(id)sender {
    [self showPasswordPopoverOnButton:sender];
}

- (void)showPasswordPopoverOnButton:(id)button {
    self.passwordPopover = [NSPopover new];
    self.passwordPopover.behavior = NSPopoverBehaviorTransient;
    self.passwordPopover.delegate = self;

    if (!self.passwordInputViewController) {
        self.passwordInputViewController = [HIPasswordInputViewController new];
        self.passwordInputViewController.prompt =
            NSLocalizedString(@"Enter your password to sign the message:", @"Password prompt for message signing");
        self.passwordInputViewController.submitLabel =
            NSLocalizedString(@"Confirm", @"Confirm button in password entry form");
    }

    __weak id weakSelf = self;
    self.passwordInputViewController.onSubmit = ^(HIPasswordHolder *passwordHolder) {
        [weakSelf signMessageWithPassword:passwordHolder];
    };

    self.passwordPopover.contentViewController = self.passwordInputViewController;
    [self.passwordPopover showRelativeToRect:[button bounds]
                                      ofView:button
                               preferredEdge:NSMaxYEdge];
}

- (void)signMessageWithPassword:(HIPasswordHolder *)password {
    NSString *message = self.messageBox.stringValue;
    NSError *error = nil;

    NSString *signature = [[HIBitcoinManager defaultManager] signMessage:message
                                                            withPassword:password.data
                                                                   error:&error];

    if (signature && !error) {
        [self.passwordPopover close];
        [self showGeneratedSignature:signature];
    } else if (error.code == kHIBitcoinManagerWrongPassword) {
        [self.window hiShake];
    } else {
        [self showAlertForError:error];
    }
}

- (void)showGeneratedSignature:(NSString *)signature {
    [self.window makeFirstResponder:nil];
    [self.signatureBox setStringValue:signature];
    [self.signatureBox selectText:self];
}

- (void)showAlertForError:(NSError *)error {
    NSAlert *alert;

    if (error) {
        alert = [NSAlert alertWithError:error];
    } else {
        alert = [NSAlert alertWithMessageText:@"Message could not be signed."
                                defaultButton:@"OK"
                              alternateButton:nil
                                  otherButton:nil
                    informativeTextWithFormat:nil];
    }

    [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
}

@end
