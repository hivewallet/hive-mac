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


/*
 Represents a single transaction made or received by the user.
 */

@interface HITransaction : NSManagedObject

// transaction id
@property (nonatomic, retain) NSString *id;

// tells if the user has already seen this transaction; unseen transactions increase the number in the dock icon badge
@property (nonatomic) BOOL read;

// transaction status (pending, building etc.)
@property (nonatomic) HITransactionStatus status;

// HITransactionDirectionIncoming or HITransactionDirectionOutgoing
@property (nonatomic, readonly, getter = direction) HITransactionDirection direction;

@property (nonatomic, readonly) BOOL isIncoming;
@property (nonatomic, readonly) BOOL isOutgoing;

// BTC amount, in satoshis; for outgoing transactions the amount is negative
@property (nonatomic) int64_t amount;

// same as amount, but it's always positive
@property (nonatomic, readonly, getter = absoluteAmount) uint64_t absoluteAmount;

// fee amount, in satoshis; for incoming transactions it will return 0
@property (nonatomic) int64_t fee;

// selected fiat currency, and amount/rate for that currency at the moment of sending
@property (nonatomic, copy) NSString *fiatCurrency;
@property (nonatomic, strong) NSDecimalNumber *fiatAmount;
@property (nonatomic, strong) NSDecimalNumber *fiatRate;

// date when transaction was sent/received
@property (nonatomic) NSDate *date;

// confusingly named, this is actually the recipient's address...
@property (nonatomic, retain) NSString *senderHash;

// aliased here for convenience
@property (nonatomic, readonly) NSString *targetAddress;

// if the address hash matches any of the contacts' addreses, contact is linked here, otherwise it's nil
@property (nonatomic, retain) HIContact *contact;

// transaction metadata (from a URI or payment request, or the contact's name)
@property (nonatomic, retain) NSString *label;
@property (nonatomic, retain) NSString *details;

// URL of the payment request, if the transaction was sent via payment request
@property (nonatomic, retain) NSString *paymentRequestURL;

// if the transaction was created from within an app
@property (nonatomic, retain) HIApplication *sourceApplication;

+ (BOOL)isAmountWithinExpectedRange:(satoshi_t)amount;

@end
