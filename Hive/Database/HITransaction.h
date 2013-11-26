//
//  HITransaction.h
//  Hive
//
//  Created by Bazyli Zygan on 18.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@class HIContact;

enum {
    TRANSACTION_STATUS_UNKNOWN = 0,
    TRANSACTION_STATUS_PENDING,
    TRANSACTION_STATUS_COMPLETE
};

typedef NS_ENUM(NSUInteger, HITransactionDirection) {
    HITransactionDirectionIncoming,
    HITransactionDirectionOutgoing
};

extern NSString * const HITransactionEntity;


/*
 Represents a single transaction made or received by the user.
 */

@interface HITransaction : NSManagedObject

// tells if the user has already seen this transaction; unseen transactions increase the number in the dock icon badge
@property (nonatomic) BOOL read;

// transaction id
@property (nonatomic, retain) NSString *id;

// BTC amount, in satoshis; for outgoing transactions the amount is negative
@property (nonatomic) int64_t amount;

// BTC address of the sender
@property (nonatomic, retain) NSString *senderHash;

// currently unused?
@property (nonatomic, retain) NSString *senderName;
@property (nonatomic, retain) NSString *senderEmail;

@property (nonatomic) NSDate *date;
@property (nonatomic) int32_t confirmations;
@property (nonatomic) BOOL request;

// if the address hash matches any of the contacts' addreses, contact is linked here, otherwise it's nil
@property (nonatomic, retain) HIContact *contact;

// HITransactionDirectionIncoming or HITransactionDirectionOutgoing
@property (nonatomic, readonly, getter = direction) HITransactionDirection direction;

// same as amount, but it's always positive
@property (nonatomic, readonly, getter = absoluteAmount) uint64_t absoluteAmount;

@end
