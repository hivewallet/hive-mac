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

@property (strong) IBOutlet NSBox *wrapper;
@property (strong) IBOutlet NSBox *separator;
@property (strong) IBOutlet NSImageView *photoView;
@property (strong) IBOutlet NSImageView *lockIcon;
@property (strong) IBOutlet NSTextField *nameLabel;
@property (strong) IBOutlet NSTextField *addressLabel;
@property (strong) IBOutlet NSTextField *amountField;
@property (strong) IBOutlet NSTextField *convertedAmountField;
@property (strong) IBOutlet NSButton *QRCodeButton;
@property (strong) IBOutlet NSView *currencyRateInfoView;
@property (strong) IBOutlet NSPopUpButton *convertedCurrencyPopupButton;
@property (strong) IBOutlet NSPopUpButton *bitcoinCurrencyPopupButton;
@property (strong) IBOutlet NSButton *feeButton;
@property (strong) IBOutlet NSButton *cancelButton;
@property (strong) IBOutlet HIButtonWithSpinner *sendButton;
@property (nonatomic, strong) IBOutlet NSButton *dropdownButton;

@property (nonatomic, assign) IBOutlet NSTextField *detailsLabel;
@property (nonatomic, assign) IBOutlet NSScrollView *detailsBox;
@property (nonatomic, assign) IBOutlet NSBox *detailsSeparator;

@property (nonatomic, strong) IBOutlet NSBox *ackBar;
@property (nonatomic, strong) IBOutlet NSTextField *ackMessage;

@property (copy) HITransactionCompletionCallback sendCompletion;

- (void)setHashAddress:(NSString *)hash;
- (void)setLockedAddress:(NSString *)hash;
- (void)setLockedAmount:(satoshi_t)amount;
- (void)setDetailsText:(NSString *)text;
- (void)setSourceApplication:(HIApplication *)application;
- (void)selectContact:(id<HIPerson>)contact;
- (void)selectContact:(id<HIPerson>)contact address:(HIAddress *)address;
- (void)lockAddress;
- (void)showPaymentRequest:(int)sessionId details:(NSDictionary *)data;

- (IBAction)cancelClicked:(id)sender;
- (IBAction)sendClicked:(id)sender;
- (IBAction)dropdownButtonClicked:(id)sender;

@end
