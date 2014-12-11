//
//  HIAppDelegate.m
//  Hive
//
//  Created by Bazyli Zygan on 11.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <BitcoinJKit/HIBitcoinErrorCodes.h>
#import <BitcoinJKit/HIBitcoinManager.h>
#import <CocoaLumberjack/DDASLLogger.h>
#import <CocoaLumberjack/DDFileLogger.h>
#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <HockeySDK/HockeySDK.h>

#import "BCClient.h"
#import "HIAboutHiveWindowController.h"
#import "HIAppDelegate.h"
#import "HIApplicationsManager.h"
#import "HIApplicationsViewController.h"
#import "HIApplicationURLProtocol.h"
#import "HIBackupCenterWindowController.h"
#import "HIBackupManager.h"
#import "HIBitcoinURIService.h"
#import "HICameraWindowController.h"
#import "HIDatabaseManager.h"
#import "HIDebuggingInfoWindowController.h"
#import "HIDebuggingToolsWindowController.h"
#import "HIErrorWindowController.h"
#import "HIExportPrivateKeyWindowController.h"
#import "HIFirstRunWizardWindowController.h"
#import "HIHiveWebWindowController.h"
#import "HILockScreenViewController.h"
#import "HILogFileManager.h"
#import "HILogFormatter.h"
#import "HIMainWindowController.h"
#import "HINetworkConnectionMonitor.h"
#import "HINotificationService.h"
#import "HIPasswordChangeWindowController.h"
#import "HIPreferencesWindowController.h"
#import "HISendBitcoinsWindowController.h"
#import "HISendFeedbackService.h"
#import "HIShortcutService.h"
#import "HISignMessageWindowController.h"
#import "HITransaction.h"
#import "HITransactionsViewController.h"
#import "HIWizardWindowController.h"
#import "NSAlert+Hive.h"
#import "PFMoveApplication.h"

static NSString * const LastVersionKey = @"LastHiveVersion";
static int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface DDLog (ExposePrivateMethod)

+ (void)queueLogMessage:(DDLogMessage *)logMessage asynchronously:(BOOL)asyncFlag;

@end

@interface HIAppDelegate () <BITHockeyManagerDelegate> {
    HIMainWindowController *_mainWindowController;
    HIPreferencesWindowController *_preferencesWindowController;
    NSMutableArray *_popupWindows;
    dispatch_queue_t _externalEventQueue;
    BOOL _initialized;
}

@property (nonatomic, strong) HIWizardWindowController *wizard;
@property (nonatomic, strong) HINetworkConnectionMonitor *networkMonitor;

@end


@implementation HIAppDelegate

#pragma mark - Initialization phase one

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
#ifndef DEBUG
    PFMoveToApplicationsFolderIfNecessary();
#endif

    _externalEventQueue = dispatch_queue_create("HIAppDelegate.externalEventQueue", DISPATCH_QUEUE_CONCURRENT);
    self.applicationLocked = YES;
    _initialized = NO;

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

    [NSURLProtocol registerClass:[HIApplicationURLProtocol class]];

    _popupWindows = [NSMutableArray new];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(popupWindowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:nil];

    [self configureShortcuts];
    [self configureMenu];

    // this must be at the end
    [self configureHockeyApp];
}

- (void)configureShortcuts {
    HIShortcutService *shortcuts = [HIShortcutService sharedService];

    shortcuts.sendBlock = ^{
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];

        if (!self.applicationLocked) {
            [self openSendBitcoinsWindow:nil];
        }
    };

    shortcuts.cameraBlock = ^{
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];

        if (!self.applicationLocked) {
            [self scanQRCode:nil];
        }
    };
}

- (void)configureMenu {
    NSArray *mainMenuItems = [[NSApp mainMenu] itemArray];
    NSMenu *helpMenu = [[mainMenuItems lastObject] submenu];
    [NSApp setHelpMenu:helpMenu];
}

- (void)configureLoggers {
    HILogFormatter *formatter = [HILogFormatter new];

    // default loggers - Console.app and Xcode console
    [DDLog addLogger:[DDASLLogger sharedInstance] withLogLevel:LOG_LEVEL_WARN];
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLogLevel:LOG_LEVEL_VERBOSE];
    [[DDTTYLogger sharedInstance] setLogFormatter:formatter];

    // file logger manager config - keep 4 log files
    HILogFileManager *logFileManager = [[HILogFileManager alloc] initWithLogsDirectory:[self logFileDirectory]];
    logFileManager.maximumNumberOfLogFiles = 4;

    // file logger config - roll file after a week or when it reaches 10 MB
    DDFileLogger *fileLogger = [[DDFileLogger alloc] initWithLogFileManager:logFileManager];
    fileLogger.rollingFrequency = 7 * 86400;
    fileLogger.maximumFileSize = 10 * 1024 * 1024;
    fileLogger.logFormatter = formatter;

    [DDLog addLogger:fileLogger withLogLevel:LOG_LEVEL_VERBOSE];

    // configure BitcoinKit logger to use CocoaLumberjack system
    [[HILogger sharedLogger] setLogHandler:logHandler];
}

- (void)configureHockeyApp {
    BITHockeyManager *hockeyapp = [BITHockeyManager sharedHockeyManager];
    [hockeyapp configureWithIdentifier:@"f5b8dab305a1fe6973043674446c7312" delegate:self];
    [hockeyapp startManager];
}

- (NSURL *)applicationFilesDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *matchingURLs = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL *appSupportURL = [matchingURLs lastObject];

    if (DEBUG_OPTION_ENABLED(TESTING_NETWORK)) {
        if (DEBUG_OPTION_ENABLED(TEMP_DIRECTORY)) {
            // We never want to combine the temp directory with a real-world wallet.
            static NSURL *url = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                url = [fileManager URLForDirectory:NSItemReplacementDirectory
                                          inDomain:NSUserDomainMask
                                 appropriateForURL:[appSupportURL URLByAppendingPathComponent:@"Hive"]
                                            create:YES
                                             error:NULL];
            });
            return url;
        } else {
            return [appSupportURL URLByAppendingPathComponent:@"HiveTest"];
        }
    } else {
        return [appSupportURL URLByAppendingPathComponent:@"Hive"];
    }
}

- (NSString *)logFileDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    NSString *logsDirectory = [basePath stringByAppendingPathComponent:@"Logs"];

    if (DEBUG_OPTION_ENABLED(TESTING_NETWORK)) {
        return [logsDirectory stringByAppendingPathComponent:@"HiveTest"];
    } else {
        return [logsDirectory stringByAppendingPathComponent:@"Hive"];
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

- (void)rebuildAppsList {
    [[HIApplicationsManager sharedManager] rebuildAppsList];
}

- (void)rebuildTransactionListIfNeeded {
    NSString *lastVersion = [[NSUserDefaults standardUserDefaults] objectForKey:LastVersionKey];
    NSString *versionAfterUpdate = @"2014090503";

    if ([lastVersion isLessThan:versionAfterUpdate]) {
        HILogInfo(@"Transaction list needs to be updated (%@ < %@)", lastVersion, versionAfterUpdate);
        [[BCClient sharedClient] repairTransactionsList];
        return;
    }
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
        [self rebuildTransactionListIfNeeded];
        [self showAppWindow];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self nagUnprotectedUsers];
            [self initializeBackups];
            [[HINotificationService sharedService] checkIfBackupsEnabled];
            [self showHiveWebAnnouncement];
            [self finishInitialization];
        });
    }
}

- (void)initializeBackups {
    [[HIBackupManager sharedManager] initializeAdapters];
    [[HIBackupManager sharedManager] performBackups];
}

- (void)startNetworkMonitor {
    self.networkMonitor = [[HINetworkConnectionMonitor alloc] init];
}

- (void)setAsDefaultHandler {
    CFStringRef bundleID = (__bridge CFStringRef) [[NSBundle mainBundle] bundleIdentifier];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, CFSTR("hiveapp"), NULL);

    LSSetDefaultHandlerForURLScheme(CFSTR("bitcoin"), bundleID);
    LSSetDefaultRoleHandlerForContentType(UTI, kLSRolesAll, bundleID);

    CFRelease(UTI);
}

- (void)showUnreadableChainFileError {
    NSString *title = NSLocalizedString(@"Bitcoin network data file could not be opened.",
                                        @"Chain file unreadable error title");
    NSString *message = NSLocalizedString(@"Hive will now delete the file and synchronize with the "
                                          @"Bitcoin network again. Please leave Hive open for the next several "
                                          @"minutes, and try not to send any transactions right now.",
                                          @"Chain file unreadable error explanation");

    [[NSAlert hiOKAlertWithTitle:title message:message] runModal];
}

- (void)showAppWindow {
    _mainWindowController = [[HIMainWindowController alloc] initWithWindowNibName:@"HIMainWindowController"];
    [_mainWindowController showWindow:self];
}

- (void)showSetUpWizard {
    self.wizard = [HIFirstRunWizardWindowController new];
    __weak __typeof__ (self) weakSelf = self;

    // make sure we don't back up new wallet to the old place (or back it up before it's created)
    [[HIBackupManager sharedManager] resetSettings];

    self.wizard.onCompletion = ^{
        [weakSelf showAppWindow];
        [weakSelf finishInitialization];

        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.wizard = nil;
        });
    };

    [self.wizard showWindow:self];
}

- (void)showInitializationError:(NSError *)error {
    NSString *message = nil;

    if (error.code == kHIBitcoinManagerUnreadableWallet) {
        message = NSLocalizedString(@"Could not read wallet file. It might be damaged.", @"initialization error");
    } else if (error.code == kHIBitcoinManagerBlockStoreLockError) {
        message = NSLocalizedString(@"Bitcoin network data file could not be opened - "
                                    @"another instance of Hive might still be running.",
                                    @"initialization error");
    } else {
        message = [error localizedFailureReason];
    }

    HILogError(@"Aborting launch because of initialization error: %@", error);

    NSAlert *alert = [NSAlert hiOKAlertWithTitle:NSLocalizedString(@"Hive cannot be started.",
                                                                   @"Initialization error title")
                                         message:message];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert runModal];

    exit(1);
}

- (void)showHiveWebAnnouncement {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:HiveWebAnnouncementDisplayedKey]) {
        [self openPopupWindowWithClass:[HIHiveWebWindowController class]];
    }
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


#pragma mark - Last initialization phase, executed asynchronously

- (void)finishInitialization {
    // Yosemite INAppStoreWindow hack
    [_mainWindowController.window becomeKeyWindow];

    [self preinstallAppsIfNeeded];
    [self rebuildAppsList];
    [self setAsDefaultHandler];
    [self startNetworkMonitor];
    [self updateLastVersionKey];

    _initialized = YES;
}


#pragma mark - App lifecycle and external actions

- (BOOL)encryptedWalletMethodsAvailable {
    return _initialized && [[BCClient sharedClient] isWalletPasswordProtected];
}

- (void)setApplicationLocked:(BOOL)applicationLocked {
    if (applicationLocked != _applicationLocked) {
        _applicationLocked = applicationLocked;

        if (applicationLocked) {
            dispatch_suspend(_externalEventQueue);
        } else {
            dispatch_resume(_externalEventQueue);
        }

        self.fullMenuEnabled = !applicationLocked;
    }
}

- (void)handleExternalEvent:(void (^)())block {
    dispatch_async(_externalEventQueue, ^{
        dispatch_async(dispatch_get_main_queue(), block);
    });

    if (self.applicationLocked) {
        [_mainWindowController showWindow:nil];
    }
}

// handler for bitcoin:xxx URLs
- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)reply {
    NSString *URIString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];

    [self handleExternalEvent:^{
        [[HIBitcoinURIService sharedService] handleBitcoinURIString:URIString];
    }];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    HILogInfo(@"Quitting Hive...");
    [[BCClient sharedClient] shutdown];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
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

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    // reopen main window after clicking on the dock icon
    [_mainWindowController showWindow:nil];
    return NO;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    if ([filename.pathExtension isEqual:@"hiveapp"]) {
        [self handleExternalEvent:^{
            HIApplicationsManager *manager = [HIApplicationsManager sharedManager];
            [manager requestLocalAppInstallation:[NSURL fileURLWithPath:filename] showAppsPage:YES error:nil];
        }];

        return YES;
    }

    if ([filename.pathExtension isEqual:@"bitcoinpaymentrequest"]) {
        __weak id delegate = self;

        [self handleExternalEvent:^{
            HIBitcoinManager *manager = [HIBitcoinManager defaultManager];
            NSError *callError = nil;

            HILogDebug(@"Opening local payment request file from %@", filename);

            [manager openPaymentRequestFromFile:filename
                                          error:&callError
                                       callback:^(NSError *loadError, int sessionId, NSDictionary *data) {
                                           if (loadError) {
                                               [self handlePaymentRequestLoadError:loadError];
                                           } else {
                                              HISendBitcoinsWindowController *window = [delegate sendBitcoinsWindow];
                                              [window showPaymentRequest:sessionId details:data];
                                              [window showWindow:self];
                                          }
                                       }];

            if (callError) {
                NSString *title = NSLocalizedString(@"Payment data file could not be opened.",
                                                    @"Alert title when payment request file can't be read");
                NSString *message = NSLocalizedString(@"The file doesn't exist or is not accessible.",
                                                      @"Alert message when payment request file can't be read");

                [[NSAlert hiOKAlertWithTitle:title message:message] runModal];
            }
        }];

        return YES;
    }

    return NO;
}

- (void)handlePaymentRequestLoadError:(NSError *)error {
    HILogDebug(@"Payment request load error: %@", error);

    NSString *title = NSLocalizedString(@"Payment data is invalid.",
                                        @"Alert title when payment request file has some invalid or unexpected data");

    NSString *message = nil;

    if (error.code == kHIBitcoinManagerInvalidProtocolBufferError) {
        message = NSLocalizedString(@"This file does not contain a valid Bitcoin payment request.",
                                    @"Alert message when payment request file isn't really a payment request at all");
    }
    else if (error.code == kHIBitcoinManagerPaymentRequestExpiredError) {
        title = NSLocalizedString(@"Payment request has already expired.",
                                  @"Alert title when the time limit to complete the payment has passed");

        message = NSLocalizedString(@"You'll need to return to the site that requested the payment "
                                    @"and initiate the payment again.",
                                    @"Alert message when the time limit to complete the payment has passed");
    }
    else if (error.code == kHIBitcoinManagerPaymentRequestWrongNetworkError) {
        message = NSLocalizedString(@"This payment is supposed to be sent on a different Bitcoin network.",
                                    @"Alert message when user is on the mainnet and payment request is for testnet "
                                    @"(or vice versa)");
    }
    else if ([error.localizedFailureReason rangeOfString:@"com.google."].location != NSNotFound) {
        // probably some less common kind of PaymentRequestException
        message = error.localizedFailureReason;
    }
    else {
        // probably an IO error, only happens for remote requests
        title = NSLocalizedString(@"Payment details could not be loaded.",
                                  @"Alert title when payment request can't be loaded from the server");

        message = NSLocalizedString(@"Check your network connection, try again later "
                                    @"or report the problem to the payment recipient.",
                                    @"Alert message when payment request can't be loaded from or sent to the server");
    }

    [[NSAlert hiOKAlertWithTitle:title message:message] runModal];
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

    if (dispatch_get_current_queue() == dispatch_get_main_queue()) {
        [AppDelegate showExceptionWindowWithException:exception];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [AppDelegate showExceptionWindowWithException:exception];
        });
    }
}


#pragma mark - Handling menu actions

- (IBAction)openSendBitcoinsWindow:(id)sender {
    [[self sendBitcoinsWindow] showWindow:self];
}

- (IBAction)changeWalletPassword:(id)sender {
    [self openPopupWindowWithClass:[HIPasswordChangeWindowController class]];
}

- (IBAction)exportPrivateKey:(id)sender {
    [self openPopupWindowWithClass:[HIExportPrivateKeyWindowController class]];
}

- (IBAction)lockWallet:(id)sender {
    [_mainWindowController.lockScreenController lockWalletAnimated:YES];
}

- (IBAction)openFAQ:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/hivewallet/hive-osx/wiki/FAQ"]];
}

- (IBAction)openSignMessageWindow:(id)sender {
    [self openPopupWindowWithClass:[HISignMessageWindowController class]];
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

- (IBAction)showAboutWindow:(id)sender {
    [self openPopupWindowWithClass:[HIAboutHiveWindowController class]];
}

- (IBAction)scanQRCode:(id)sender {
    [HICameraWindowController sharedCameraWindowController].delegate = nil;
    [[HICameraWindowController sharedCameraWindowController] showWindow:self];
}

- (IBAction)sendFeedback:(id)sender {
    [[HISendFeedbackService sharedService] sendSupportEmail];
}

- (IBAction)openPreferences:(id)sender {
    if (!_preferencesWindowController) {
        _preferencesWindowController = [HIPreferencesWindowController new];
    }
    [_preferencesWindowController showWindow:self];
    [_popupWindows addObject:_preferencesWindowController];
}

#pragma mark - Window handling

- (void)showWindowWithPanel:(Class)panelClass {
    [_mainWindowController showWindow:nil];
    [_mainWindowController switchToPanel:panelClass];
}

- (void)showExceptionWindowWithException:(NSException *)exception {
    HILogWarn(@"Caught exception: %@", exception.reason);

    NSString *javaStackTrace = exception.userInfo[@"stackTrace"];
    if (javaStackTrace) {
        HILogWarn(@"Java stack trace:\n%@", javaStackTrace);
    }

    if (exception.callStackSymbols) {
        HILogWarn(@"Cocoa stack trace:\n%@", exception.callStackSymbols);
    }

    for (NSWindowController *wc in _popupWindows) {
        if ([wc isKindOfClass:[HIErrorWindowController class]]) {
            // don't show a whole cascade of error windows
            HILogDebug(@"Ignoring exception because error window is already open.");
            return;
        }
    }

    HIErrorWindowController *window = [[HIErrorWindowController alloc] initWithException:exception];
    [window showWindow:self];
    [_popupWindows addObject:window];
}

- (HISendBitcoinsWindowController *)sendBitcoinsWindowForContact:(HIContact *)contact {
    HISendBitcoinsWindowController *wc = [self sendBitcoinsWindow];
    [wc selectContact:contact];
    return wc;
}

- (HISendBitcoinsWindowController *)sendBitcoinsWindow {
    HISendBitcoinsWindowController *wc = [[HISendBitcoinsWindowController alloc] init];
    [wc window];
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
