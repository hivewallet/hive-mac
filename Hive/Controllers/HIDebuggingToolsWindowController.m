//
//  HIDebuggingToolsWindowController.m
//  Hive
//
//  Created by Jakub Suder on 25.11.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HIDebuggingToolsWindowController.h"

@interface HIDebuggingToolsWindowController ()

- (IBAction)rebuildTransactionList:(id)sender;

@end

@implementation HIDebuggingToolsWindowController

- (id)init
{
    return [super initWithWindowNibName:@"HIDebuggingToolsWindowController"];
}

- (IBAction)rebuildTransactionList:(id)sender
{
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Are you sure?",
                                                                     @"Debugging tools confirmation popup title")
                                     defaultButton:NSLocalizedString(@"Rebuild list",
                                                                     @"Rebuild transaction list button title")
                                   alternateButton:NSLocalizedString(@"Cancel",
                                                                     @"Cancel button title")
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"Your transaction list will be rebuilt now.",
                                                                     @"Rebuild transaction list popup description")];

    [alert beginSheetModalForWindow:self.window
                      modalDelegate:self
                     didEndSelector:@selector(rebuildTransactionListAlertClosed:withReturnCode:context:)
                        contextInfo:NULL];
}

- (void)rebuildTransactionListAlertClosed:(NSAlert *)alert withReturnCode:(NSInteger)code context:(void *)context
{
    if (code == NSAlertDefaultReturn)
    {
        [[BCClient sharedClient] clearTransactionsList];
        [[BCClient sharedClient] rebuildTransactionsList];
    }
}

@end
