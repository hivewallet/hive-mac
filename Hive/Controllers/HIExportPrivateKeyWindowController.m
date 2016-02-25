//
//  HIExportPrivateKeyWindowController.m
//  Hive
//
//  Created by Jakub Suder on 14/10/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import <BitcoinJKit/HIBitcoinErrorCodes.h>
#import <BitcoinJKit/HIBitcoinManager.h>
#import "BCClient.h"
#import "HIExportPrivateKeyWindowController.h"
#import "HIPasswordHolder.h"
#import "HIPasswordInputViewController.h"
#import "NSWindow+HIShake.h"

@interface HIExportPrivateKeyWindowController () <NSPopoverDelegate>

@property (nonatomic, strong) HIPasswordInputViewController *passwordInputViewController;
@property (nonatomic, strong) NSPopover *passwordPopover;
@property (nonatomic, strong) NSString *exportedPrivateKey;

@end


@implementation HIExportPrivateKeyWindowController

- (instancetype)init {
    return [super initWithWindowNibName:self.className];
}

- (IBAction)cancelPressed:(id)sender {
    [self close];
}

- (IBAction)exportPressed:(id)sender {
    [self showPasswordPopoverOnButton:sender];
}

- (void)showPasswordPopoverOnButton:(id)button {
    self.passwordPopover = [NSPopover new];
    self.passwordPopover.behavior = NSPopoverBehaviorTransient;
    self.passwordPopover.delegate = self;

    if (!self.passwordInputViewController) {
        self.passwordInputViewController = [HIPasswordInputViewController new];
        self.passwordInputViewController.prompt =
            NSLocalizedString(@"Enter your password to export the key:",
                              @"Password prompt for private key export");
        self.passwordInputViewController.submitLabel =
            NSLocalizedString(@"Confirm", @"Confirm button in password entry form");
    }

    __unsafe_unretained id weakSelf = self;
    self.passwordInputViewController.onSubmit = ^(HIPasswordHolder *passwordHolder) {
        [weakSelf exportKeyWithPassword:passwordHolder];
    };

    self.passwordPopover.contentViewController = self.passwordInputViewController;
    [self.passwordPopover showRelativeToRect:[button bounds]
                                      ofView:button
                               preferredEdge:NSMaxYEdge];
}

- (void)exportKeyWithPassword:(HIPasswordHolder *)password {
    NSError *error = nil;

    NSString *privateKey = [[HIBitcoinManager defaultManager] exportPrivateKeyWithPassword:password.data
                                                                                     error:&error];

    if (privateKey && !error) {
        self.exportedPrivateKey = privateKey;

        [self.passwordPopover close];
        [self showSaveDialog];
    } else if (error.code == kHIBitcoinManagerWrongPassword) {
        [self.window hiShake];
    } else {
        [self showAlertForError:error];
    }
}

- (void)showSaveDialog {
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.nameFieldStringValue = @"hive-private-key.key";

    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [self exportKeyToURL:panel.URL];
        } else {
            self.exportedPrivateKey = nil;
        }
    }];
}

- (void)exportKeyToURL:(NSURL *)url {
    NSError *error = nil;

    NSString *header =
    @"# === WARNING ===\n"
    @"# Anyone who can see the information below has access to all your bitcoins.\n"
    @"# Don't share this file with anyone, don't put it in any folder that's synced to the cloud or accessible from\n"
    @"# the network, and delete it immediately when you no longer need it.\n"
    @"#\n"
    @"# The file format is compatible with Multibit:\n"
    @"# <private key in WIF format> <key creation date (ISO 8601 compatible)>\n";

    NSString *contents = [NSString stringWithFormat:@"%@\n%@\n", header, self.exportedPrivateKey];

    BOOL saved = [contents writeToURL:url atomically:YES encoding:NSASCIIStringEncoding error:&error];

    if (saved && !error) {
        self.exportedPrivateKey = nil;
        [self close];
    } else {
        [self showAlertForError:error];
    }
}

- (void)showAlertForError:(NSError *)error {
    NSAlert *alert;

    if (error) {
        alert = [NSAlert alertWithError:error];
    } else {
        alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Private key could not be exported.",
                                                                @"Message when private key export fails")
                                defaultButton:NSLocalizedString(@"OK", @"OK button title")
                              alternateButton:nil
                                  otherButton:nil
                    informativeTextWithFormat:@""];
    }

    [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
}

@end
