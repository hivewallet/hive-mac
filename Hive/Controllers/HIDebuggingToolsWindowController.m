//
//  HIDebuggingToolsWindowController.m
//  Hive
//
//  Created by Jakub Suder on 25.11.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <BitcoinJKit/BitcoinJKit.h>
#import "BCClient.h"
#import "HIApplicationsManager.h"
#import "HIDebuggingToolsWindowController.h"

@interface HIDebuggingToolsWindowController ()

@property (nonatomic, strong) IBOutlet NSTextField *progressLabel;
@property (nonatomic, strong) IBOutlet NSProgressIndicator *progressBar;

- (IBAction)rebuildApplicationListClicked:(id)sender;
- (IBAction)rebuildTransactionListClicked:(id)sender;
- (IBAction)rebuildWalletClicked:(id)sender;
- (IBAction)reinstallBundledAppsClicked:(id)sender;

@end

@implementation HIDebuggingToolsWindowController

- (id)init {
    return [super initWithWindowNibName:@"HIDebuggingToolsWindowController"];
}

- (void)awakeFromNib {
    [[HIBitcoinManager defaultManager] addObserver:self
                                        forKeyPath:@"syncProgress"
                                           options:NSKeyValueObservingOptionInitial
                                           context:NULL];
}

- (void)dealloc {
    [[HIBitcoinManager defaultManager] removeObserver:self forKeyPath:@"syncProgress"];
}

- (IBAction)rebuildTransactionListClicked:(id)sender {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Are you sure?"
                                     defaultButton:@"Rebuild list"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@"Your transaction list will be rebuilt now."];

    [alert beginSheetModalForWindow:self.window
                      modalDelegate:self
                     didEndSelector:@selector(alertClosed:withReturnCode:context:)
                        contextInfo:@selector(rebuildTransactionList)];
}

- (IBAction)rebuildApplicationListClicked:(id)sender {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Are you sure?"
                                     defaultButton:@"Rebuild application list"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@"Your application list will be rebuilt now."];

    [alert beginSheetModalForWindow:self.window
                      modalDelegate:self
                     didEndSelector:@selector(alertClosed:withReturnCode:context:)
                        contextInfo:@selector(rebuildApplicationList)];
}

- (IBAction)reinstallBundledAppsClicked:(id)sender {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Are you sure?"
                                     defaultButton:@"Reinstall apps"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@"Any changes you've made to the code in those apps will be lost."];

    [alert beginSheetModalForWindow:self.window
                      modalDelegate:self
                     didEndSelector:@selector(alertClosed:withReturnCode:context:)
                        contextInfo:@selector(reinstallBundledApps)];
}

- (IBAction)rebuildWalletClicked:(id)sender {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Are you sure?"
                                     defaultButton:@"Rebuild wallet"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@"Your wallet data will be rebuilt now. "
                                                   @"This will take some time to complete."];

    [alert beginSheetModalForWindow:self.window
                      modalDelegate:self
                     didEndSelector:@selector(alertClosed:withReturnCode:context:)
                        contextInfo:@selector(rebuildWallet)];
}

- (void)alertClosed:(NSAlert *)alert withReturnCode:(NSInteger)code context:(void *)context {
    if (code == NSAlertDefaultReturn) {
        SEL selector = (SEL) context;

        dispatch_async(dispatch_get_main_queue(), ^{
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:selector withObject:nil];
            #pragma clang diagnostic pop
        });
    }
}

- (void)rebuildTransactionList {
    [[BCClient sharedClient] repairTransactionsList];
}

- (void)rebuildApplicationList {
    [[HIApplicationsManager sharedManager] rebuildAppsList];
}

- (void)reinstallBundledApps {
    [[HIApplicationsManager sharedManager] preinstallApps];
}

- (void)rebuildWallet {
    NSError *error = nil;
    NSAlert *alert;

    [[HIBitcoinManager defaultManager] resetBlockchain:&error];

    if (error) {
        alert = [NSAlert alertWithError:error];
    } else {
        alert = [NSAlert alertWithMessageText:@"Wallet is now being rebuilt."
                                defaultButton:@"OK"
                              alternateButton:nil
                                  otherButton:nil
                    informativeTextWithFormat:@"It's not recommended to send any transactions "
                                              @"until the sync is complete."];
    }

    [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
}

- (void)observeValueForKeyPath:(NSString *)path ofObject:(id)object change:(NSDictionary *)change context:(void *)ctx {
    if (object == [HIBitcoinManager defaultManager]) {
        float progress = [[HIBitcoinManager defaultManager] syncProgress];
        self.progressLabel.stringValue = [NSString stringWithFormat:@"%.1f%%", progress];
        self.progressBar.doubleValue = progress;
    }
}

@end
