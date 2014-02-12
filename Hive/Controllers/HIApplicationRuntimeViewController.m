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

@interface WebView (HIItsThere)

- (void)setScriptDebugDelegate:(id)scriptDebugDelegate;

@end

@interface WebScriptCallFrame

@property (nonatomic, copy, readonly) NSString *functionName;
@property (nonatomic, copy, readonly) id exception;

@end

@interface HIApplicationRuntimeViewController () {
    HIAppRuntimeBridge *_bridge;
    NSURL *_baseURL;
    NSMutableDictionary *_sourceFiles;
}

@end

@implementation HIApplicationRuntimeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        // Initialization code here.
        _sourceFiles = [NSMutableDictionary new];
    }
    
    return self;
}

- (void)loadView {
    [super loadView];

    self.title = self.application.name;

    _bridge = [[HIAppRuntimeBridge alloc] initWithApplication:self.application frame:self.webView.mainFrame];
    _bridge.controller = self;

    WebView *webView = self.webView;
    if ([webView respondsToSelector:@selector(setScriptDebugDelegate:)]) {
        [webView setScriptDebugDelegate:self];
    }

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
                      amount:(satoshi_t)amount
                  completion:(HITransactionCompletionCallback)completion {
    HIAppDelegate *delegate = (HIAppDelegate *) [NSApp delegate];
    HISendBitcoinsWindowController *sc = [delegate sendBitcoinsWindow];
    [sc setLockedAddress:hash];
    [sc setSendCompletion:completion];

    if (amount) {
        [sc setLockedAmount:amount];
    }

    [sc showWindow:self];
}

- (void)viewWillDisappear {
    [_bridge killCallbacks];
    [self.webView.mainFrame loadHTMLString:@"" baseURL:nil];
}

#pragma mark - Delegate for WebView

- (void)webView:(WebView *)wv runJavaScriptAlertPanelWithMessage:(NSString *)msg initiatedByFrame:(WebFrame *)frame {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:self.application.name];
    [alert setInformativeText:msg];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", @"OK button title")];
    
    [alert beginSheetModalForWindow:self.view.window
                      modalDelegate:nil
                     didEndSelector:nil
                        contextInfo:NULL];
}

- (BOOL)webView:(WebView *)wv runJavaScriptConfirmPanelWithMessage:(NSString *)msg initiatedByFrame:(WebFrame *)frame {
    NSAlert *alert = [NSAlert alertWithMessageText:self.application.name
                                     defaultButton:NSLocalizedString(@"OK", @"OK button title")
                                   alternateButton:NSLocalizedString(@"Cancel", @"Cancel button title")
                                       otherButton:nil
                         informativeTextWithFormat:@"%@", msg];

    NSInteger result = [alert runModal];

    return (result == NSAlertDefaultReturn);
}

- (void)webView:(WebView *)sender
                   resource:(id)identifier
    didFailLoadingWithError:(NSError *)error
             fromDataSource:(WebDataSource *)dataSource {
    HILogWarn(@"App loading error: %@", error);

    NSURL *URL = error.userInfo[NSURLErrorFailingURLErrorKey];

    if ([URL isEqual:_baseURL]) {
        NSRunAlertPanel(NSLocalizedString(@"Application can't be loaded", @"App load error title"),
                        NSLocalizedString(@"The application data file has been removed or corrupted.",
                                          @"App load error description"),
                        NSLocalizedString(@"OK", @"OK button title"),
                        nil, nil);
    }
}

- (void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame {
    // make the bridge object accessible from JS
    id window = self.webView.windowScriptObject;

    [window setValue:_bridge forKey:@"bitcoin"];

}

// we should be able to handle this in webView:createWebViewWithRequest:, but webkit is stupid and returns nil there
- (void)webView:(WebView *)webView
decidePolicyForNewWindowAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
   newFrameName:(NSString *)frameName
decisionListener:(id<WebPolicyDecisionListener>)listener {
    [[NSWorkspace sharedWorkspace] openURL:request.URL];
}

- (void)dealloc {
    id window = [self.webView windowScriptObject];
    [window removeObjectForKey:@"bitcoin"];
}

#pragma mark - ScriptDebugDelegate

- (void)webView:(WebView *)webView
 didParseSource:(NSString *)source
 baseLineNumber:(unsigned)lineNumber
        fromURL:(NSURL *)url
       sourceId:(int)sid
    forWebFrame:(WebFrame *)webFrame {

    if (url.absoluteString.lastPathComponent) {
        _sourceFiles[@(sid)] = url.absoluteString.lastPathComponent;
    }
}

- (void)webView:(WebView *)webView
    failedToParseSource:(NSString *)source
 baseLineNumber:(unsigned)lineNumber
        fromURL:(NSURL *)url
      withError:(NSError *)error
    forWebFrame:(WebFrame *)webFrame {

    NSString *fileName = [NSString stringWithFormat:@"%@:%@", self.title, source];

    HILoggerLog(fileName.UTF8String, "", lineNumber, HILoggerLevelError, @"Parse error: %@", source);
}


- (void)webView:(WebView *)webView
exceptionWasRaised:(WebScriptCallFrame *)frame
       sourceId:(int)sid
           line:(int)lineNumber
    forWebFrame:(WebFrame *)webFrame {

    // http://gf3.ca/read/exception-introspection
    [webFrame.windowObject setValue:frame.exception forKey:@"__GC_frame_exception"];
    NSString *exceptionRef = [webFrame.windowObject evaluateWebScript:@"__GC_frame_exception.constructor.name"];
    NSString *stackTrace = [webFrame.windowObject evaluateWebScript:@"__GC_frame_exception.stack"];
    [webFrame.windowObject setValue:nil forKey:@"__GC_frame_exception"];

    NSString *fileName = [NSString stringWithFormat:@"%@:%@", self.title, _sourceFiles[@(sid)]];
    NSString *formattedStrackTrace =
        [[stackTrace componentsSeparatedByString:@"\n"] componentsJoinedByString:@"\n\tat "];

    HILoggerLog(fileName.UTF8String, (frame.functionName ?: @"").UTF8String, lineNumber, HILoggerLevelError,
        @"%@\n%@", exceptionRef, formattedStrackTrace);
}

@end
