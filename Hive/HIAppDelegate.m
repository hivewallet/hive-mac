//
//  HIAppDelegate.m
//  Hive
//
//  Created by Bazyli Zygan on 11.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <BitcoinJKit/HIBitcoinErrorCodes.h>
#import <WebKit/WebKit.h>

#import "BCClient.h"
#import "HIAppDelegate.h"
#import "HIApplicationsManager.h"
#import "HIApplicationURLProtocol.h"
#import "HIBitcoinURL.h"
#import "HIDatabaseManager.h"
#import "HIDebuggingInfoWindowController.h"
#import "HIDebuggingToolsWindowController.h"
#import "HIErrorWindowController.h"
#import "HIMainWindowController.h"
#import "HISendBitcoinsWindowController.h"
#import "HITransaction.h"

static NSString * const LastVersionKey = @"LastHiveVersion";
static NSString * const WarningDisplayedKey = @"WarningDisplayed";


@interface HIAppDelegate () {
    HIDebuggingInfoWindowController *_debuggingInfoWindowController;
    HIDebuggingToolsWindowController *_debuggingToolsWindowController;
    HIMainWindowController *_mainWindowController;
    NSMutableArray *_popupWindows;
}

@end


@implementation HIAppDelegate

void handleException(NSException *exception) {
    [[NSApp delegate] showExceptionWindowWithException:exception];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    BITHockeyManager *hockeyapp = [BITHockeyManager sharedHockeyManager];
    [hockeyapp configureWithIdentifier:@"e47f0624d130a873ecae31509e4d1124"
                           companyName:@""
                              delegate:self];
    [hockeyapp startManager];

    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
     @"Currency": @1,
     @"FirstRun": @YES,
     @"LastBalance": @0,
     @"Profile": @{},
     @"WebKitDeveloperExtras": @YES
    }];

    [NSURLProtocol registerClass:[HIApplicationURLProtocol class]];

    _popupWindows = [NSMutableArray new];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(popupWindowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:nil];

    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleURLEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];

    [self showBetaWarning];
    [self preinstallAppsIfNeeded];
    [self rebuildTransactionListIfNeeded];
    [self updateLastVersionKey];
}

- (void)showMainApplicationWindowForCrashManager:(id)crashManager {
    NSError *error = nil;
    [[BCClient sharedClient] start:&error];
    if (error) {
        [self showInitializationError:error];
    } else {
        _mainWindowController = [[HIMainWindowController alloc] initWithWindowNibName:@"HIMainWindowController"];
        [_mainWindowController showWindow:self];
    }

    NSSetUncaughtExceptionHandler(&handleException);
}

- (void)showInitializationError:(NSError *)error {
    // TODO: Look at error code (e.g. kHIBitcoinManagerUnreadableWallet) and offer specific solution.
    NSString *message = nil;
    if (error.code == kHIBitcoinManagerUnreadableWallet) {
        message = NSLocalizedString(@"Could not read wallet file. It might be damaged.", @"initialization error");
    } else if (error.code == kHIBitcoinManagerBlockStoreError) {
        message = NSLocalizedString(@"Could not write wallet file. Another instance of Hive might still be running.",
                                    @"initialization error");
    }
    if (message) {
        [[NSAlert alertWithMessageText:NSLocalizedString(@"Error", @"Initialization error title")
                         defaultButton:NSLocalizedString(@"OK", @"OK button title")
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:@"%@", message] runModal];
    } else {
        [[NSAlert alertWithError:error] runModal];
    }
    exit(1);
}

- (void)showBetaWarning {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (![defaults objectForKey:WarningDisplayedKey]) {
        NSRunAlertPanel(@"Warning",
                        @"This version is for testing and development purposes only! "
                        @"Please do not move any money into it that you cannot afford to lose.",
                        @"OK", nil, nil);

        [defaults setObject:@(YES) forKey:WarningDisplayedKey];
    }
}

- (void)preinstallAppsIfNeeded {
    NSString *currentVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
    NSString *lastVersion = [[NSUserDefaults standardUserDefaults] objectForKey:LastVersionKey];

    if (!lastVersion || [currentVersion isGreaterThan:lastVersion]) {
        [[HIApplicationsManager sharedManager] preinstallApps];
    }
}

- (void)updateLastVersionKey {
    NSString *currentVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
    [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:LastVersionKey];
}

- (void)rebuildTransactionListIfNeeded {
    NSString *lastVersion = [[NSUserDefaults standardUserDefaults] objectForKey:LastVersionKey];

    if ([lastVersion isLessThan:@"2013112601"]) {
        // rebuild the list once after changing HITransaction#date from NSTimeInterval to NSDate
        // (which is how it was actually defined in the data model from the beginning)

        [[BCClient sharedClient] clearTransactionsList];
        [[BCClient sharedClient] rebuildTransactionsList];
    }
}

// Returns the directory the application uses to store the Core Data store file.
- (NSURL *)applicationFilesDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *matchingURLs = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL *appSupportURL = [matchingURLs lastObject];

    if (DEBUG_OPTION_ENABLED(TESTING_NETWORK)) {
        return [appSupportURL URLByAppendingPathComponent:@"HiveTest"];
    } else {
        return [appSupportURL URLByAppendingPathComponent:@"Hive"];
    }
}

// handler for bitcoin:xxx URLs
- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)reply {
    NSString *URLString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    HIBitcoinURL *bitcoinURL = [[HIBitcoinURL alloc] initWithURLString:URLString];

    if (bitcoinURL.valid) {
        HISendBitcoinsWindowController *window = [self sendBitcoinsWindow];

        if (bitcoinURL.address) {
            [window setHashAddress:bitcoinURL.address];
        }

        if (bitcoinURL.amount) {
            [window setLockedAmount:bitcoinURL.amount];
        }

        [window showWindow:self];
    }
}

// Returns the NSUndoManager for the application.
// In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [DBM undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's
// managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender {
    NSError *error = nil;

    if (![DBM commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", self.class, NSStringFromSelector(_cmd));
    }

    if (![DBM save:&error]) {
        [NSApp presentError:error];
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification {
//    [[BCClient sharedClient] shutdown];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save changes in the application's managed object context before the application terminates.

    if (!DBM) {
        return NSTerminateNow;
    }

    if (![DBM commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", self.class, NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }

    if (![DBM hasChanges]) {
        return NSTerminateNow;
    }

    NSError *error = nil;

    if (![DBM save:&error]) {
        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?",
                                               @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made "
                                           @"since the last successful save",
                                           @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");

        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];

        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication {
    [_mainWindowController showWindow:nil];
    return  NO;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    if ([filename.pathExtension isEqual:@"hiveapp"]) {
        HIApplicationsManager *manager = [HIApplicationsManager sharedManager];
        NSURL *applicationURL = [NSURL fileURLWithPath:filename];
        NSDictionary *manifest = [manager applicationMetadata:applicationURL];

        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"Install Hive App", @"Install app popup title")];
        [alert addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"No", nil)];

        NSString *text;

        if ([manager hasApplicationOfId:manifest[@"id"]]) {
            text = NSLocalizedString(@"You already have \"%@\" application. Would you like to overwrite it?",
                                     @"Install app popup confirmation when app exists");
        } else {
            text = NSLocalizedString(@"Would you like to install \"%@\" application?",
                                     @"Install app popup confirmation");
        }

        [alert setInformativeText:[NSString stringWithFormat:text, manifest[@"name"]]];

        if ([alert runModal] == NSAlertFirstButtonReturn) {
            [manager installApplication:applicationURL];
        }

        return YES;
    }

    return NO;
}

- (IBAction)openSendBitcoinsWindow:(id)sender {
    [[self sendBitcoinsWindow] showWindow:self];
}

- (IBAction)openCoinMapSite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://coinmap.org"]];
}

- (IBAction)showDebuggingInfo:(id)sender {
    if (!_debuggingInfoWindowController) {
        _debuggingInfoWindowController = [[HIDebuggingInfoWindowController alloc] init];
        [_popupWindows addObject:_debuggingInfoWindowController];
    }

    [_debuggingInfoWindowController showWindow:self];
}

- (IBAction)showDebuggingTools:(id)sender {
    if (!_debuggingToolsWindowController) {
        _debuggingToolsWindowController = [[HIDebuggingToolsWindowController alloc] init];
        [_popupWindows addObject:_debuggingToolsWindowController];
    }

    [_debuggingToolsWindowController showWindow:self];
}

- (void)showExceptionWindowWithException:(NSException *)exception {
    HIErrorWindowController *window = [[HIErrorWindowController alloc] initWithException:exception];
    [window showWindow:self];
    [_popupWindows addObject:window];
}

- (HISendBitcoinsWindowController *)sendBitcoinsWindowForContact:(HIContact *)contact {
    HISendBitcoinsWindowController *wc = [[HISendBitcoinsWindowController alloc] initWithContact:contact];
    [_popupWindows addObject:wc];
    return wc;
}

- (HISendBitcoinsWindowController *)sendBitcoinsWindow {
    HISendBitcoinsWindowController *wc = [[HISendBitcoinsWindowController alloc] init];
    [_popupWindows addObject:wc];
    return wc;
}

- (void)popupWindowWillClose:(NSNotification *)notification {
    NSWindowController *wc = notification.object;
    [_popupWindows removeObject:wc];

    if (wc == _debuggingInfoWindowController) {
        _debuggingInfoWindowController = nil;
    }
}

@end
