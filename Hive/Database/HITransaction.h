//
//  HITransaction.h
//  Hive
//
//  Created by Bazyli Zygan on 18.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

@class HIApplication;
@class HIContact;

typedef NS_ENUM(int16_t, HITransactionStatus) {
    HITransactionStatusUnknown = 0,      // we don't know yet what the status is
    HITransactionStatusPending = 1,      // transaction was broadcasted, but not included in a block yet
    HITransactionStatusBuilding = 2,     // transaction was included in at least one block
    HITransactionStatusDead = 3,         // transaction was cancelled by the network
};

typedef NS_ENUM(NSUInteger, HITransactionDirection) {
    HITransactionDirectionIncoming,      // we're receiving the money
    HITransactionDirectionOutgoing       // we're sending the money
};



extern NSString * const HITransactionEntity;

// thrown when transaction direction cannot be determined
extern NSString * const HITransactionDirectionUnknownException;


/*
 Represents a single transaction made or received by the user.
 */

@interface HITransaction : NSManagedObject

// transaction id
@property (nonatomic, copy) NSString *id;

// tells if the user has already seen this transaction; unseen transactions increase the number in the dock icon badge
@property (nonatomic, assign) BOOL read;

// transaction status (pending, building etc.)
@property (nonatomic, assign) HITransactionStatus status;

// HITransactionDirectionIncoming or HITransactionDirectionOutgoing
@property (nonatomic, readonly) HITransactionDirection direction;

@property (nonatomic, readonly) BOOL isIncoming;
@property (nonatomic, readonly) BOOL isOutgoing;

// BTC amount, in satoshis; for outgoing transactions the amount is negative
@property (nonatomic, assign) int64_t amount;

// same as amount, but it's always positive
@property (nonatomic, readonly) uint64_t absoluteAmount;

// fee amount, in satoshis; for incoming transactions it will return 0
@property (nonatomic, assign) int64_t fee;

// selected fiat currency, and amount/rate for that currency at the moment of sending
@property (nonatomic, copy) NSString *fiatCurrency;
@property (nonatomic, strong) NSDecimalNumber *fiatAmount;
@property (nonatomic, strong) NSDecimalNumber *fiatRate;

// date when transaction was sent/received
@property (nonatomic, copy) NSDate *date;

@property (nonatomic, copy) NSString *sourceAddress;
@property (nonatomic, copy) NSString *targetAddress;

// if the address hash matches any of the contacts' addreses, contact is linked here, otherwise it's nil
@property (nonatomic, strong) HIContact *contact;

// transaction metadata (from a URI or payment request, or the contact's name)
@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSString *details;

// URL of the payment request, if the transaction was sent via payment request
@property (nonatomic, copy) NSString *paymentRequestURL;

// if the transaction was created from within an app
@property (nonatomic, strong) HIApplication *sourceApplication;

+ (BOOL)isAmountWithinExpectedRange:(satoshi_t)amount;

@end
