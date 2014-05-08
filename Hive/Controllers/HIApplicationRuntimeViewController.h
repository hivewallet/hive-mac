//
//  HIApplicationRuntimeViewController.h
//  Hive
//
//  Created by Bazyli Zygan on 27.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIApplication.h"
#import "HISendBitcoinsWindowController.h"
#import "HIViewController.h"

/*
 Runs the selected application in a web view and manages its communication with Hive.
 */

@interface HIApplicationRuntimeViewController : HIViewController

@property (strong) HIApplication *application;
@property (weak) IBOutlet WebView *webView;

- (void)requestPaymentToHash:(NSString *)hash
                      amount:(satoshi_t)amount
                  completion:(HITransactionCompletionCallback)completion;

@end
