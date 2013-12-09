//
//  HIDebuggingToolsWindowController.m
//  Hive
//
//  Created by Jakub Suder on 25.11.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HIApplicationsManager.h"
#import "HIDebuggingToolsWindowController.h"

@implementation HIDebuggingToolsWindowController

- (id)init {
    return [super initWithWindowNibName:@"HIDebuggingToolsWindowController"];
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

- (void)alertClosed:(NSAlert *)alert withReturnCode:(NSInteger)code context:(void *)context {
    if (code == NSAlertDefaultReturn) {
        SEL selector = (SEL) context;
        [self performSelector:selector withObject:nil];
    }
}

- (void)rebuildTransactionList {
    [[BCClient sharedClient] clearTransactionsList];
    [[BCClient sharedClient] rebuildTransactionsList];
}

- (void)rebuildApplicationList {
    [[HIApplicationsManager sharedManager] rebuildAppsList];
}

- (void)reinstallBundledApps {
    [[HIApplicationsManager sharedManager] preinstallApps];
}

@end
