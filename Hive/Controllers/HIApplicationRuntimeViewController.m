//
//  HIApplicationRuntimeViewController.m
//  Hive
//
//  Created by Bazyli Zygan on 27.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIAppDelegate.h"
#import "HIApplicationRuntimeViewController.h"
#import "HIAppRuntimeBridge.h"
#import "HIMainWindowController.h"
#import "HISendBitcoinsWindowController.h"

@interface WebPreferences (ItsThere)

- (void)setWebSecurityEnabled:(BOOL)yesNo;

@end

@interface HIApplicationRuntimeViewController ()
{
    HIAppRuntimeBridge *_bridge;
}

@end

@implementation HIApplicationRuntimeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)loadView
{
    [super loadView];

    self.title = self.application.name;

    // make the bridge object accessible from JS
    id window = self.webView.windowScriptObject;

    _bridge = [[HIAppRuntimeBridge alloc] init];
    _bridge.frame = [self.webView mainFrame];
    _bridge.controller = self;

    [window setValue:_bridge forKey:@"bitcoin"];

    // disable cross-site security check
    NSString *noSecurityPreferencesId = @"noSecurity";
    WebPreferences *prefs = [[WebPreferences alloc] initWithIdentifier:noSecurityPreferencesId];
    [prefs setWebSecurityEnabled:NO];
    [self.webView setPreferencesIdentifier:noSecurityPreferencesId];

    // load the app
    BOOL isDirectory = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:self.application.path.path isDirectory:&isDirectory];

    NSURL *URLToLoad;

    if (isDirectory)
    {
        URLToLoad = [self.application.path URLByAppendingPathComponent:@"index.html"];
    }
    else
    {
        URLToLoad = [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost/%@/index.html",
                                          self.application.id]];
    }

    [self.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:URLToLoad]];
}


#pragma mark - Money sends

- (void)requestPaymentToHash:(NSString *)hash
                      amount:(NSDecimalNumber *)amount
                  completion:(void(^)(BOOL success, NSString *hash))completion
{
    HIAppDelegate *d = (HIAppDelegate *)[NSApp delegate];
    HISendBitcoinsWindowController *sc = [d sendBitcoinsWindow];
    [sc setHashAddress:hash];
    [sc setLockedAmount:amount];
    sc.sendCompletion = ^(BOOL success, NSDecimalNumber *amount, NSString *hash) {
        if (completion)
        {
            completion(success, hash);
        }
    };
    [sc showWindow:self];
}

- (void)viewWillDisappear
{
    [_bridge killCallbacks];
    [self.webView.mainFrame loadHTMLString:@"" baseURL:nil];
}

#pragma mark - Delegate for WebView

- (void)webView:(WebView *)sender
    runJavaScriptAlertPanelWithMessage:(NSString *)message
                      initiatedByFrame:(WebFrame *)frame
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:self.application.name];
    [alert setInformativeText:message];
    [alert addButtonWithTitle:@"Ok"];
    
    [alert runModal];
}

- (void)webView:(WebView *)sender
                   resource:(id)identifier
    didFailLoadingWithError:(NSError *)error
             fromDataSource:(WebDataSource *)dataSource
{
    NSRunAlertPanel(NSLocalizedString(@"Application can't be loaded", @"App load error title"),
                    NSLocalizedString(@"A network error has occurred or the application data file "
                                      @"has been removed or corrupted.", @"App load error description"),
                    NSLocalizedString(@"OK", @"OK Button title"),
                    nil, nil);
}

- (void)dealloc
{
    id window = [self.webView windowScriptObject];
    [window removeObjectForKey:@"bitcoin"];
}

@end
