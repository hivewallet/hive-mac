//
//  HIAppRuntimeBridge.h
//  Hive
//
//  Created by Bazyli Zygan on 27.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIJavaScriptObject.h"

@class HIApplication;
@class HIApplicationRuntimeViewController;

/*
 Implements the window.bitcoin object in the application's JS context that acts as a gateway between the app
 and Hive.
 */

@interface HIAppRuntimeBridge : HIJavaScriptObject

@property (strong) HIApplicationRuntimeViewController *controller;

+ (BOOL)isApiVersionInApplicationSupported:(HIApplication *)application;

- (instancetype)initWithApplication:(HIApplication *)application frame:(WebFrame *)frame;

- (void)killCallbacks;

- (void)sendMoneyToAddress:(NSString *)hash amount:(NSNumber *)amount callback:(WebScriptObject*)callback;
- (void)transactionWithHash:(NSString *)hash callback:(WebScriptObject *)callback;
- (void)getUserInformationWithCallback:(WebScriptObject *)callback;

@end
