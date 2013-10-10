//
//  HIContact.h
//  Hive
//
//  Created by Bazyli Zygan on 18.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HITransaction;
@class HIAddress;

extern NSString * const HIContactEntity;


/*
 Represents a contact from the contacts list.
 */

@interface HIContact : NSManagedObject

@property (nonatomic, retain) NSString * account;
@property (nonatomic, retain) NSData * avatar;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * firstname;
@property (nonatomic, retain) NSString * lastname;
@property (nonatomic, retain) NSOrderedSet *transactions;
@property (nonatomic, readonly, getter = name) NSString *name;
@property (nonatomic, readonly, getter = avatarImage) NSImage *avatarImage;
@property (nonatomic, retain) NSSet *addresses;

- (BOOL)canBeRemoved;
- (BOOL)canEditAddresses;

@end

@interface HIContact (CoreDataGeneratedAccessors)

- (void)insertObject:(HITransaction *)value inTransactionsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromTransactionsAtIndex:(NSUInteger)idx;
- (void)insertTransactions:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeTransactionsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInTransactionsAtIndex:(NSUInteger)idx withObject:(HITransaction *)value;
- (void)replaceTransactionsAtIndexes:(NSIndexSet *)indexes withTransactions:(NSArray *)values;
- (void)addTransactionsObject:(HITransaction *)value;
- (void)removeTransactionsObject:(HITransaction *)value;
- (void)addTransactions:(NSOrderedSet *)values;
- (void)removeTransactions:(NSOrderedSet *)values;
- (void)addAddressesObject:(HIAddress *)value;
- (void)removeAddressesObject:(HIAddress *)value;
@end
