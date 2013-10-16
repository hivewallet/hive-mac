//
//  HIAppRuntimeBridge.h
//  Hive
//
//  Created by Bazyli Zygan on 27.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

#import "HIApplicationRuntimeViewController.h"

/*
 Implements the window.bitcoin object in the application's JS context that acts as a gateway between the app
 and Hive.
 */

@interface HIAppRuntimeBridge : NSObject

@property (strong) HIApplicationRuntimeViewController *controller;
@property (strong) WebFrame *frame;

- (void)killCallbacks;

- (void)sendMoneyToAddress:(NSString *)hash amount:(id)amount callback:(WebScriptObject*)callback;
- (void)transactionWithHash:(NSString *)hash callback:(WebScriptObject *)callback;
- (void)getUserInformationWithCallback:(WebScriptObject *)callback;

@end
