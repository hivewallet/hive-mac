//
//  HIDebuggingInfoWindowController.m
//  Hive
//
//  Created by Jakub Suder on 29.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <BitcoinJKit/BitcoinJKit.h>
#import "HIBitcoinFormatService.h"
#import "HIDatabaseManager.h"
#import "HIDebuggingInfoWindowController.h"
#import "HITransaction.h"

@interface HIDebuggingInfoWindowController()

@property (nonatomic, strong) IBOutlet NSTextView *textView;  // NSTextView doesn't support weak references

@end

@implementation HIDebuggingInfoWindowController

- (instancetype)init {
    return [self initWithWindowNibName:@"HIDebuggingInfoWindowController"];
}

- (void)awakeFromNib {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateInfo];
    });
}

- (void)updateInfo {
    NSMutableString *info = [[NSMutableString alloc] init];
    HIBitcoinManager *bitcoin = [HIBitcoinManager defaultManager];
    HIBitcoinFormatService *formatService = [HIBitcoinFormatService sharedService];

    [info appendFormat:@"## Basic info\n\n"];
    [info appendFormat:@"Data generated at: %@\n", [NSDate date]];
    [info appendFormat:@"Wallet address: %@\n", bitcoin.walletAddress];

    [info appendFormat:@"Available balance: %lld (%@)\n",
                       bitcoin.availableBalance,
                       [formatService stringWithUnitForBitcoin:bitcoin.availableBalance]];
    [info appendFormat:@"Estimated balance: %lld (%@)\n",
                       bitcoin.estimatedBalance,
                       [formatService stringWithUnitForBitcoin:bitcoin.estimatedBalance]];

    NSFetchRequest *transactionRequest = [NSFetchRequest fetchRequestWithEntityName:HITransactionEntity];
    transactionRequest.returnsObjectsAsFaults = NO;
    NSArray *transactions = [DBM executeFetchRequest:transactionRequest error:NULL];

    [info appendFormat:@"Data store transactions count: %ld\n", transactions.count];
    [info appendFormat:@"Wallet transactions count: %ld\n", bitcoin.allTransactions.count];

    [info appendFormat:@"Sync progress: %.1f%%\n", bitcoin.syncProgress];

    [info appendFormat:@"\n## Data store transactions\n\n"];
    [info appendFormat:@"%@\n", transactions];

    [info appendFormat:@"\n## Wallet transactions\n\n"];
    [info appendFormat:@"%@\n", bitcoin.allTransactions];

    [info appendFormat:@"\n## Wallet details\n\n"];
    [info appendString:bitcoin.walletDebuggingInfo];

    self.textView.string = info;
}

- (IBAction)openLogDirectoryPressed:(id)sender {
    NSFileManager *manager = [NSFileManager defaultManager];

    NSURL *library = [[manager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL *logs = [library URLByAppendingPathComponent:@"Logs"];
    NSURL *hiveLogs = [logs URLByAppendingPathComponent:@"Hive"];

    if ([manager fileExistsAtPath:hiveLogs.path isDirectory:NULL]) {
        [[NSWorkspace sharedWorkspace] openURL:hiveLogs];
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Hive log directory not found."
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"This shouldn't happen :("];

        [alert beginSheetModalForWindow:self.window
                          modalDelegate:nil
                         didEndSelector:nil
                            contextInfo:NULL];
    }
}

- (IBAction)saveToFilePressed:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];

    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSError *error = nil;
            NSString *path = panel.URL.path;

            if (path.pathExtension.length == 0) {
                path = [path stringByAppendingString:@".txt"];
            }

            [self.textView.string writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];

            [panel orderOut:nil];

            if (error) {
                HILogError(@"Couldn't save debugging info to %@: %@", path, error);

                [[NSAlert alertWithError:error] beginSheetModalForWindow:self.window
                                                           modalDelegate:nil
                                                          didEndSelector:nil
                                                             contextInfo:NULL];
            }
        }
    }];
}

@end
