//
//  HISendBitcoinsWindowController.h
//  Hive
//
//  Created by Jakub Suder on 05.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIContact.h"
#import "HIContactAutocompleteWindowController.h"

@class HIButtonWithSpinner;
@class HIApplication;

extern NSString * const HISendBitcoinsWindowDidClose;
extern NSString * const HISendBitcoinsWindowSuccessKey;

typedef void(^HITransactionCompletionCallback)(BOOL success, NSString *transactionId);

/*
 Manages the "Send Bitcoin" window.
 */

@interface HISendBitcoinsWindowController : NSWindowController
    <HIContactAutocompleteDelegate, NSWindowDelegate, NSControlTextEditingDelegate>

@property (nonatomic, copy) HITransactionCompletionCallback sendCompletion;

- (void)setHashAddress:(NSString *)hash;
- (void)setLockedAddress:(NSString *)hash;
- (void)setLockedAmount:(satoshi_t)amount;
- (void)setDetailsText:(NSString *)text;
- (void)setSourceApplication:(HIApplication *)application;
- (void)selectContact:(id<HIPerson>)contact;
- (void)selectContact:(id<HIPerson>)contact address:(HIAddress *)address;
- (void)lockAddress;
- (void)showPaymentRequest:(int)sessionId details:(NSDictionary *)data;
- (void)showPaymentRequestLoadingBox;
- (void)hidePaymentRequestLoadingBox;

- (IBAction)cancelClicked:(id)sender;
- (IBAction)sendClicked:(id)sender;
- (IBAction)dropdownButtonClicked:(id)sender;

@end
