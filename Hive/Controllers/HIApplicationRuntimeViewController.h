//
//  HIApplicationRuntimeViewController.h
//  Hive
//
//  Created by Bazyli Zygan on 27.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "HIViewController.h"
#import "HIApplication.h"

@interface HIApplicationRuntimeViewController : HIViewController

@property (strong) HIApplication *application;
@property (weak) IBOutlet WebView *webView;

- (void)requestPaymentToHash:(NSString *)hash
                      amount:(NSDecimalNumber *)amount
                  completion:(void(^)(BOOL success, NSString *hash))completion;

- (void)requestPaymentWithAddressToHash:(NSString *)hash
                                 amount:(NSDecimalNumber *)amount
                             completion:(void(^)(BOOL success, NSString *hash, NSDictionary *address))completion;

@end
