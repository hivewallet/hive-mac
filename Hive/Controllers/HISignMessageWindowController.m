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

@property (weak) IBOutlet NSTextField *messageBox;
@property (weak) IBOutlet NSTextField *signatureBox;

@property (strong) HIPasswordInputViewController *passwordInputViewController;
@property (strong) NSPopover *passwordPopover;

@end


@implementation HISignMessageWindowController

- (instancetype)init {
    return [super initWithWindowNibName:self.className];
}

- (IBAction)cancelPressed:(id)sender {
    [self close];
}

- (IBAction)signPressed:(id)sender {
    if ([[BCClient sharedClient] isWalletPasswordProtected]) {
        [self showPasswordPopoverOnButton:sender];
    } else {
        [self signMessageWithPassword:nil];
    }
}

- (void)showPasswordPopoverOnButton:(id)button {
    self.passwordPopover = [NSPopover new];
    self.passwordPopover.behavior = NSPopoverBehaviorTransient;
    self.passwordPopover.delegate = self;

    if (!self.passwordInputViewController) {
        self.passwordInputViewController = [HIPasswordInputViewController new];
        self.passwordInputViewController.prompt =
            NSLocalizedString(@"Enter your password to sign the message:", @"Passphrase prompt for message signing");
        self.passwordInputViewController.submitLabel =
            NSLocalizedString(@"Confirm", @"Confirm button next to passphrase");
    }

    __unsafe_unretained id weakSelf = self;
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
