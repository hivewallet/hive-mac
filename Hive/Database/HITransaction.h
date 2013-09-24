//
//  HITransaction.h
//  Hive
//
//  Created by Bazyli Zygan on 18.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

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


@interface HITransaction : NSManagedObject

@property (nonatomic) BOOL read;
@property (nonatomic, retain) NSString * id;
@property (nonatomic) int64_t amount;
@property (nonatomic, retain) NSString * senderName;
@property (nonatomic, retain) NSString * senderHash;
@property (nonatomic) NSTimeInterval date;
@property (nonatomic, retain) NSString * senderEmail;
@property (nonatomic) int32_t confirmations;
@property (nonatomic) BOOL request;
@property (nonatomic, retain) HIContact *contact;

@property (nonatomic, readonly, getter = dateObject) NSDate *dateObject;
@property (nonatomic, readonly, getter = direction) HITransactionDirection direction;
@property (nonatomic, readonly, getter = absoluteAmount) uint64_t absoluteAmount;

@end
