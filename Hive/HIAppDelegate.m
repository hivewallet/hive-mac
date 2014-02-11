//
//  HIAppDelegate.m
//  Hive
//
//  Created by Bazyli Zygan on 11.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <BitcoinJKit/HIBitcoinErrorCodes.h>
#import <BitcoinJKit/HIBitcoinManager.h>
#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDASLLogger.h>
#import <CocoaLumberjack/DDFileLogger.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <HockeySDK/HockeySDK.h>
#import <WebKit/WebKit.h>

#import "BCClient.h"
#import "HIAppDelegate.h"
#import "HIApplicationsManager.h"
#import "HIApplicationsViewController.h"
#import "HIApplicationURLProtocol.h"
#import "HIBackupCenterWindowController.h"
#import "HIBackupManager.h"
#import "HIBitcoinUrlService.h"
#import "HICameraWindowController.h"
#import "HIDatabaseManager.h"
#import "HIDebuggingInfoWindowController.h"
#import "HIDebuggingToolsWindowController.h"
#import "HIErrorWindowController.h"
#import "HIFirstRunWizardWindowController.h"
#import "HILogFormatter.h"
#import "HIMainWindowController.h"
#import "HINotificationService.h"
#import "HIPasswordChangeWindowController.h"
#import "HISendBitcoinsWindowController.h"
#import "HISendFeedbackService.h"
#import "HITransaction.h"
#import "HITransactionsViewController.h"
#import "HIWizardWindowController.h"
#import "PFMoveApplication.h"

static NSString * const LastVersionKey = @"LastHiveVersion";
static NSString * const WarningDisplayedKey = @"WarningDisplayed";

static int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface DDLog (ExposePrivateMethod)

+ (void)queueLogMessage:(DDLogMessage *)logMessage asynchronously:(BOOL)asyncFlag;

@end

@interface HIAppDelegate ()<BITHockeyManagerDelegate> {
    HIMainWindowController *_mainWindowController;
    NSMutableArray *_popupWindows;
}

@property (nonatomic, strong) HIWizardWindowController *wizard;
@property (nonatomic, assign, getter=isFullMenuEnabled) BOOL fullMenuEnabled;

@end


@implementation HIAppDelegate

#pragma mark - Initialization phase one

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
#ifndef DEBUG
    PFMoveToApplicationsFolderIfNecessary();
#endif

    // this needs to be set up *before* applicationDidFinishLaunching,
    // otherwise links that cause the app to be launched when it's not running will not be handled
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleURLEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self configureLoggers];

    HILogInfo(@"Starting Hive v. %@...", [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"]);

    [self configureHockeyApp];

    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
     @"WebKitDeveloperExtras": @YES
    }];

    [NSURLProtocol registerClass:[HIApplicationURLProtocol class]];

    _popupWindows = [NSMutableArray new];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(popupWindowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:nil];

    [self preinstallAppsIfNeeded];
    [self rebuildTransactionListIfNeeded];
    [self updateLastVersionKey];
}

- (void)configureLoggers {
    HILogFormatter *formatter = [HILogFormatter new];

    // default loggers - Console.app and Xcode console
    [DDLog addLogger:[DDASLLogger sharedInstance] withLogLevel:LOG_LEVEL_WARN];
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLogLevel:LOG_LEVEL_VERBOSE];
    [[DDTTYLogger sharedInstance] setLogFormatter:formatter];

    // file logger
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];

    // roll file after a week or when it reaches 10 MB
    fileLogger.rollingFrequency = 7 * 86400;
    fileLogger.maximumFileSize = 10 * 1024 * 1024;
    fileLogger.logFormatter = formatter;

    // keep 4 log files, use timestamps for naming
    DDLogFileManagerDefault *logFileManager = (DDLogFileManagerDefault *) fileLogger.logFileManager;
    logFileManager.maximumNumberOfLogFiles = 4;

    [DDLog addLogger:fileLogger withLogLevel:LOG_LEVEL_VERBOSE];

    // configure BitcoinKit logger to use CocoaLumberjack system
    [[HILogger sharedLogger] setLogHandler:logHandler];
}

- (void)configureHockeyApp {
    BITHockeyManager *hockeyapp = [BITHockeyManager sharedHockeyManager];
    [hockeyapp configureWithIdentifier:@"e47f0624d130a873ecae31509e4d1124"
                           companyName:@""
                              delegate:self];
    [hockeyapp startManager];
}

- (void)initializeBackups {
    [[HIBackupManager sharedManager] initializeAdapters];
    [[HIBackupManager sharedManager] performBackups];
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
    NSString *versionAfterUpdate = @"2014012001";

    if ([lastVersion isLessThan:versionAfterUpdate]) {
        HILogInfo(@"Transaction list needs to be rebuild (%@ < %@)", lastVersion, versionAfterUpdate);
        [[BCClient sharedClient] clearTransactionsList];
        [[BCClient sharedClient] rebuildTransactionsList];
        return;
    }

    // we should be able to remove this in a few versions, this only happens if you run older versions of Hive
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HITransactionEntity];
    request.predicate = [NSPredicate predicateWithFormat:@"date > %@", [NSDate date]];
    NSUInteger count = [DBM countForFetchRequest:request error:NULL];

    if (count > 0) {
        HILogInfo(@"Found some transactions with invalid date, rebuilding transaction list");
        [[BCClient sharedClient] clearTransactionsList];
        [[BCClient sharedClient] rebuildTransactionsList];
    }
}

- (NSURL *)applicationFilesDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *matchingURLs = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL *appSupportURL = [matchingURLs lastObject];

    if (DEBUG_OPTION_ENABLED(TESTING_NETWORK)) {
        if (DEBUG_OPTION_ENABLED(TEMP_DIRECTORY)) {
            // We never want to combine the temp directory with a real-world wallet.
            return [fileManager URLForDirectory:NSItemReplacementDirectory
                                       inDomain:NSUserDomainMask
                              appropriateForURL:[appSupportURL URLByAppendingPathComponent:@"Hive"]
                                         create:YES
                                          error:NULL];
        } else {
            return [appSupportURL URLByAppendingPathComponent:@"HiveTest"];
        }
    } else {
        return [appSupportURL URLByAppendingPathComponent:@"Hive"];
    }
}


#pragma mark - Initialization phase two (BCClient and main window)

- (void)showMainApplicationWindowForCrashManager:(id)crashManager {
    if (!DBM) {
        exit(1);
    }

    [self configureNotifications];
    [self startBitcoinClientWithPreviousError:nil];

    NSSetUncaughtExceptionHandler(&handleException);
}

- (void)startBitcoinClientWithPreviousError:(NSError *)previousError {
    NSError *error = nil;
    [[BCClient sharedClient] start:&error];

    if (error.code == kHIBitcoinManagerNoWallet) {
        [self showSetUpWizard];
    } else if (error.code == kHIBitcoinManagerBlockStoreReadError && !previousError) {
        [self showUnreadableChainFileError];
        [[HIBitcoinManager defaultManager] deleteBlockchainDataFile:nil];
        [self startBitcoinClientWithPreviousError:error];
    } else if (error) {
        HILogError(@"BitcoinManager start error: %@", error);
        [self showInitializationError:error];
    } else {
        [self showAppWindow];
        [self nagUnprotectedUsers];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self setAsDefaultHandler];
            [self initializeBackups];
        });
    }
}

- (void)showUnreadableChainFileError {
    NSString *title = NSLocalizedString(@"Bitcoin network data file could not be opened.",
                                        @"Chain file unreadable error title");
    NSString *message = NSLocalizedString(@"Hive will now delete the file and synchronize with the "
                                          @"Bitcoin network again.",
                                          @"Chain file unreadable error explanation");

    NSAlert *alert = [NSAlert alertWithMessageText:title
                                     defaultButton:NSLocalizedString(@"OK", @"OK button title")
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"%@", message];

    [alert runModal];
}

- (void)setAsDefaultHandler {
    CFStringRef bundleID = (__bridge CFStringRef) [[NSBundle mainBundle] bundleIdentifier];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, CFSTR("hiveapp"), NULL);

    LSSetDefaultHandlerForURLScheme(CFSTR("bitcoin"), bundleID);
    LSSetDefaultRoleHandlerForContentType(UTI, kLSRolesAll, bundleID);
}

- (void)showAppWindow {
    self.fullMenuEnabled = YES;

    _mainWindowController = [[HIMainWindowController alloc] initWithWindowNibName:@"HIMainWindowController"];
    [_mainWindowController showWindow:self];
}

- (void)showSetUpWizard {
    self.wizard = [HIFirstRunWizardWindowController new];
    __weak __typeof__ (self) weakSelf = self;

    self.wizard.onCompletion = ^{
        [weakSelf showAppWindow];
    };

    [self.wizard showWindow:self];
}

- (void)configureNotifications {
    __weak __typeof__ (self) weakSelf = self;
    HINotificationService *notificationService = [HINotificationService sharedService];

    notificationService.onTransactionClicked = ^{
        [weakSelf showWindowWithPanel:[HITransactionsViewController class]];
    };

    notificationService.onBackupErrorClicked = ^{
        [weakSelf showBackupCenter:nil];
    };

    notificationService.enabled = YES;
}

- (void)showInitializationError:(NSError *)error {
    NSString *message = nil;

    if (error.code == kHIBitcoinManagerUnreadableWallet) {
        message = NSLocalizedString(@"Could not read wallet file. It might be damaged.", @"initialization error");
    } else if (error.code == kHIBitcoinManagerBlockStoreLockError) {
        message = NSLocalizedString(@"Bitcoin network data file could not be opened. "
                                    @"Another instance of Hive might still be running.",
                                    @"initialization error");
    } else {
        message = [error localizedFailureReason];
    }

    HILogError(@"Aborting launch because of initialization error: %@", error);

    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Hive cannot be started.",
                                                                     @"Initialization error title")
                                     defaultButton:NSLocalizedString(@"OK", @"OK button title")
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"%@", message];

    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert runModal];

    exit(1);
}

#pragma mark - nag unprotected users

- (void)nagUnprotectedUsers {
    if (![[BCClient sharedClient] isWalletPasswordProtected]) {
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"Your wallet does not have a password!";
        alert.alertStyle = NSWarningAlertStyle;
        alert.informativeText = @"You should select a password as soon as possible!";
        [alert addButtonWithTitle:@"Select password now"];
        [alert addButtonWithTitle:@"Later"];
        [alert beginSheetModalForWindow:_mainWindowController.window
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:nil];
    }
}

- (void)alertDidEnd:(NSAlert *)alert
         returnCode:(NSInteger)returnCode
        contextInfo:(void *)contextInfo {

    if (returnCode == NSAlertFirstButtonReturn) {
        [self changeWalletPassword:nil];
    }
}

#pragma mark - App lifecycle and external actions

// handler for bitcoin:xxx URLs
- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)reply {
    NSString *URLString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    // run this asynchronously, in case the app is still launching and UI is not fully set up yet
    dispatch_async(dispatch_get_main_queue(), ^{
        [[HIBitcoinUrlService sharedService] handleBitcoinUrlString:URLString];
    });
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
        HILogError(@"Unable to commit editing before saving");
    }

    if (![DBM save:&error]) {
        [NSApp presentError:error];
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    HILogInfo(@"Quitting Hive...");
    [[BCClient sharedClient] shutdown];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save changes in the application's managed object context before the application terminates.

    if (!DBM) {
        return NSTerminateNow;
    }

    if (![DBM commitEditing]) {
        HILogError(@"Unable to commit editing to terminate");
        return NSTerminateCancel;
    }

    NSError *error = nil;

    if ([DBM hasChanges] && ![DBM save:&error]) {
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

    if ([[HIBitcoinManager defaultManager] isSyncing] && [[BCClient sharedClient] hasPendingTransactions]) {
        NSString *title = NSLocalizedString(@"Hive is currently syncing with the Bitcoin network. "
                                            @"Are you sure you want to quit?",
                                            @"Sync in progress alert title");

        NSString *message = NSLocalizedString(@"Your pending transactions won't be confirmed "
                                              @"until the sync is complete.",
                                              @"Sync in progress alert details");

        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");

        NSAlert *alert = [NSAlert alertWithMessageText:title
                                         defaultButton:quitButton
                                       alternateButton:cancelButton
                                           otherButton:nil
                             informativeTextWithFormat:@"%@", message];

        if ([alert runModal] != NSAlertDefaultReturn) {
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
        NSString *title, *info, *confirm;

        if ([manager hasApplicationOfId:manifest[@"id"]]) {
            title = NSLocalizedString(@"You have already added \"%@\" to Hive. Would you like to overwrite it?",
                                      @"Install app popup title when app exists");

            info = NSLocalizedString(@"The existing app file will be replaced by the new version. "
                                     @"This will not affect any app settings or saved data.",
                                     @"Install app popup warning message when app exists");

            confirm = NSLocalizedString(@"Reinstall", @"Install app button title when app exists");
        } else {
            title = NSLocalizedString(@"Do you want to add \"%@\" to Hive?",
                                      @"Install app popup title");

            info = NSLocalizedString(@"We cannot guarantee the safety of all apps - please be careful "
                                     @"if you download Hive apps from third party sites.",
                                     @"Install app popup warning message");

            confirm = NSLocalizedString(@"Install", @"Install app button title");
        }

        [alert setMessageText:[NSString stringWithFormat:title, manifest[@"name"]]];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:confirm];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];

        if ([alert runModal] == NSAlertFirstButtonReturn) {
            [manager installApplication:applicationURL];
            [self showWindowWithPanel:[HIApplicationsViewController class]];
        }

        return YES;
    }

    return NO;
}


#pragma mark - Logs

static void (^logHandler)(const char*, const char*, int, HILoggerLevel, NSString*) =
    ^(const char *fileName, const char *functionName, int lineNumber, HILoggerLevel level, NSString *message) {

    int flag;

    switch (level) {
        case HILoggerLevelInfo:
            flag = LOG_FLAG_INFO;
            break;
        case HILoggerLevelWarn:
            flag = LOG_FLAG_WARN;
            break;
        case HILoggerLevelError:
            flag = LOG_FLAG_ERROR;
            break;
        default:
            flag = LOG_FLAG_DEBUG;
            break;
    }

    DDLogMessage *log = [[DDLogMessage alloc] initWithLogMsg:message
                                                       level:ddLogLevel
                                                        flag:flag
                                                     context:0
                                                        file:fileName
                                                    function:functionName
                                                        line:lineNumber
                                                         tag:nil
                                                     options:DDLogMessageCopyFile | DDLogMessageCopyFunction];

    [DDLog queueLogMessage:log asynchronously:YES];
};


#pragma mark - Exceptions handling

void handleException(NSException *exception) {
    HILogError(@"Exception caught: %@", exception);

    [[NSApp delegate] showExceptionWindowWithException:exception];
}


#pragma mark - Handling menu actions

- (IBAction)openSendBitcoinsWindow:(id)sender {
    [[self sendBitcoinsWindow] showWindow:self];
}

- (IBAction)changeWalletPassword:(id)sender {
    [self openPopupWindowWithClass:[HIPasswordChangeWindowController class]];
}

- (IBAction)openCoinMapSite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://coinmap.org"]];
}

- (IBAction)showDebuggingInfo:(id)sender {
    [self openPopupWindowWithClass:[HIDebuggingInfoWindowController class]];
}

- (IBAction)showDebuggingTools:(id)sender {
    [self openPopupWindowWithClass:[HIDebuggingToolsWindowController class]];
}

- (IBAction)showBackupCenter:(id)sender {
    [self openPopupWindowWithClass:[HIBackupCenterWindowController class]];
}

- (IBAction)scanBarcode:(id)sender {
    [self openPopupWindowWithClass:[HICameraWindowController class]];
}

- (IBAction)sendFeedback:(id)sender {
    [[HISendFeedbackService sharedService] sendSupportEmail];
}

#pragma mark - Window handling

- (void)showWindowWithPanel:(Class)panelClass {
    [_mainWindowController showWindow:nil];
    [_mainWindowController switchToPanel:panelClass];
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
    [_popupWindows removeObject:[notification.object delegate]];
}

- (void)openPopupWindowWithClass:(Class)klass {
    NSWindowController *controller = nil;

    for (NSWindowController *wc in _popupWindows) {
        if ([wc isKindOfClass:klass]) {
            controller = wc;
            break;
        }
    }

    if (!controller) {
        controller = [[klass alloc] init];
        [_popupWindows addObject:controller];
    }

    [controller showWindow:self];
}

@end
