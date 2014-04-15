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
#import <WebKit/WebKit.h>

#import "BCClient.h"
#import "HIAboutHiveWindowController.h"
#import "HIAppDelegate.h"
#import "HIApplicationsManager.h"
#import "HIApplicationsViewController.h"
#import "HIApplicationURLProtocol.h"
#import "HIBackupCenterWindowController.h"
#import "HIBackupManager.h"
#import "HIBitcoinURLService.h"
#import "HICameraWindowController.h"
#import "HIDatabaseManager.h"
#import "HIDebuggingInfoWindowController.h"
#import "HIDebuggingToolsWindowController.h"
#import "HIErrorWindowController.h"
#import "HIFirstRunWizardWindowController.h"
#import "HILockScreenViewController.h"
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
#import "PFMoveApplication.h"

static NSString * const LastVersionKey = @"LastHiveVersion";
static NSString * const WarningDisplayedKey = @"WarningDisplayed";

static int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface DDLog (ExposePrivateMethod)

+ (void)queueLogMessage:(DDLogMessage *)logMessage asynchronously:(BOOL)asyncFlag;

@end

@interface HIAppDelegate () <BITHockeyManagerDelegate> {
    HIMainWindowController *_mainWindowController;
    HIPreferencesWindowController *_preferencesWindowController;
    NSMutableArray *_popupWindows;
    dispatch_queue_t _externalEventQueue;
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

    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
      // enable WebKit inspector in apps
      @"WebKitDeveloperExtras": @YES,

      // enable lock screen on startup, unless it's explicitly disabled
      LockScreenEnabledDefaultsKey: @YES,
    }];

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
    [HIShortcutService sharedService].sendBlock = ^{
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        [self openSendBitcoinsWindow:nil];
    };
    [HIShortcutService sharedService].cameraBlock = ^{
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        [self scanQRCode:nil];
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
    [hockeyapp configureWithIdentifier:@"f5b8dab305a1fe6973043674446c7312"
                           companyName:@"Hive"
                              delegate:self];
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

    NSAlert *alert = [NSAlert alertWithMessageText:title
                                     defaultButton:NSLocalizedString(@"OK", @"OK button title")
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"%@", message];

    [alert runModal];
}

- (void)showAppWindow {
    _mainWindowController = [[HIMainWindowController alloc] initWithWindowNibName:@"HIMainWindowController"];
    [_mainWindowController showWindow:self];
}

- (void)showSetUpWizard {
    self.wizard = [HIFirstRunWizardWindowController new];
    __weak __typeof__ (self) weakSelf = self;

    self.wizard.onCompletion = ^{
        [weakSelf showAppWindow];
        [weakSelf finishInitialization];
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


#pragma mark - Last initialization phase, executed asynchronously

- (void)finishInitialization {
    [self preinstallAppsIfNeeded];
    [self rebuildAppsList];
    [self setAsDefaultHandler];
    [self startNetworkMonitor];
    [self updateLastVersionKey];
}


#pragma mark - App lifecycle and external actions

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
    NSString *URLString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];

    [self handleExternalEvent:^{
        [[HIBitcoinURLService sharedService] handleBitcoinURLString:URLString];
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

- (IBAction)lockWallet:(id)sender {
    [_mainWindowController.lockScreenController lockWalletAnimated:YES];
}

- (IBAction)openCoinMapSite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://coinmap.org"]];
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
    [self openPreferences:sender];
    [_preferencesWindowController selectBackupCenter];
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
