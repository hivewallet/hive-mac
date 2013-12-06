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
    NSURL *_baseURL;
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

    _bridge = [[HIAppRuntimeBridge alloc] initWithApplication:self.application];
    _bridge.frame = [self.webView mainFrame];
    _bridge.controller = self;

    // set custom user agent
    NSString *hiveVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    self.webView.applicationNameForUserAgent = [NSString stringWithFormat:@"Hive/%@", hiveVersion];

    // disable cross-site security check
    NSString *noSecurityPreferencesId = @"noSecurity";
    WebPreferences *prefs = [[WebPreferences alloc] initWithIdentifier:noSecurityPreferencesId];
    [prefs setWebSecurityEnabled:NO];
    [self.webView setPreferencesIdentifier:noSecurityPreferencesId];

    // load the app
    _baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@.hiveapp/index.html", self.application.id]];

    [self.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:_baseURL]];
}


#pragma mark - Money sends

- (void)requestPaymentToHash:(NSString *)hash
                      amount:(NSDecimalNumber *)amount
                  completion:(HITransactionCompletionCallback)completion
{
    HIAppDelegate *delegate = (HIAppDelegate *) [NSApp delegate];
    HISendBitcoinsWindowController *sc = [delegate sendBitcoinsWindow];
    [sc setHashAddress:hash];
    [sc setSendCompletion:completion];

    if (amount)
    {
        [sc setLockedAmount:amount];
    }

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
    NSLog(@"App loading error: %@", error);

    NSURL *URL = error.userInfo[NSURLErrorFailingURLErrorKey];

    if ([URL isEqual:_baseURL])
    {
        NSRunAlertPanel(NSLocalizedString(@"Application can't be loaded", @"App load error title"),
                        NSLocalizedString(@"The application data file has been removed or corrupted.",
                                          @"App load error description"),
                        NSLocalizedString(@"OK", @"OK Button title"),
                        nil, nil);
    }
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    // make the bridge object accessible from JS
    id window = self.webView.windowScriptObject;

    [window setValue:_bridge forKey:@"bitcoin"];

}

// we should be able to handle this in webView:createWebViewWithRequest:, but webkit is stupid and returns nil there
- (void)webView:(WebView *)webView
decidePolicyForNewWindowAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
   newFrameName:(NSString *)frameName
decisionListener:(id<WebPolicyDecisionListener>)listener
{
    [[NSWorkspace sharedWorkspace] openURL:request.URL];
}

- (void)dealloc
{
    id window = [self.webView windowScriptObject];
    [window removeObjectForKey:@"bitcoin"];
}

@end
