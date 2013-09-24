//
//  HIApplicationRuntimeViewController.m
//  Hive
//
//  Created by Bazyli Zygan on 27.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIApplicationRuntimeViewController.h"
#import "HIAppRuntimeBridge.h"
#import "HIMainWindowController.h"
#import "HIAppDelegate.h"
#import "HISendBitcoinsWindowController.h"

@interface WebPreferences (ItsThere)

- (void)setWebSecurityEnabled:(BOOL)yesNo;

@end

@interface HIApplicationRuntimeViewController ()
{
    HIAppRuntimeBridge *_bridge;
}

- (void)requestFinished:(id)sender;
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
    id win = [self.webView windowScriptObject];
    _bridge = [[HIAppRuntimeBridge alloc] init];
    _bridge.frame = [self.webView mainFrame];
    _bridge.controller = self;
    [win setValue:_bridge forKey:@"bitcoin"];
    NSString* noSecurityPreferencesId = @"noSecurity";
    WebPreferences* prefs = [[WebPreferences alloc] initWithIdentifier: noSecurityPreferencesId];
    [prefs setWebSecurityEnabled:NO];
    [_webView setPreferencesIdentifier: noSecurityPreferencesId];
    BOOL dir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:self.application.path.path isDirectory:&dir];
    if (dir)
        [[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[self.application.path URLByAppendingPathComponent:@"index.html"]]];
    else
        [[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost/%@/index.html", self.application.id]]]];
}

#pragma mark - Money sends

- (void)requestPaymentWithAddressToHash:(NSString *)hash amount:(CGFloat)amount completion:(void(^)(BOOL success, NSString *hash, NSDictionary *address))completion
{
    HIAppDelegate *d = (HIAppDelegate *)[NSApp delegate];
    HISendBitcoinsWindowController *sc = [d sendBitcoinsWindow];
    [sc setHashAddress:hash];
    [sc setLockedAmount:amount];
    sc.sendCompletion = ^(BOOL success, double amount, NSString *hash) {
        if (completion)
            completion(success, hash, nil);
    };
    [sc showWindow:self];    
}

- (void)requestPaymentToHash:(NSString *)hash amount:(CGFloat)amount completion:(void(^)(BOOL success, NSString *hash))completion
{
    HIAppDelegate *d = (HIAppDelegate *)[NSApp delegate];
    HISendBitcoinsWindowController *sc = [d sendBitcoinsWindow];
    [sc setHashAddress:hash];
    [sc setLockedAmount:amount];
    sc.sendCompletion = ^(BOOL success, double amount, NSString *hash) {
        if (completion)
            completion(success, hash);
    };
    [sc showWindow:self];
}

- (void)requestFinished:(id)sender
{
}

- (void)viewWillDisappear
{
    [_bridge killCallbacks];
    [[_webView mainFrame] loadHTMLString:@"" baseURL:nil];
}

#pragma mark - Delegate for WebView


- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource
{
//    if ([request.URL.lastPathComponent compare:@"bitcoin.js"] == NSOrderedSame)
//    {
//        return [NSURLRequest requestWithURL:[[NSBundle mainBundle] URLForResource:@"bitcoin" withExtension:@"js"]];
//    }
    
    return request;
}

- (void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WebFrame *)frame
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:_application.name];
    [alert setInformativeText:message];
    [alert addButtonWithTitle:@"Ok"];
    
    [alert runModal];
}

- (void)dealloc
{
    id win = [self.webView windowScriptObject];
    [win removeObjectForKey:@"bitcoin"];
}
@end
