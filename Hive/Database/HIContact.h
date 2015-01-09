//
//  HIContact.h
//  Hive
//
//  Created by Bazyli Zygan on 18.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIPerson.h"

@class HITransaction;
@class HIAddress;

extern NSString * const HIContactEntity;

/*
 Represents a contact from the contacts list.
 */

@interface HIContact : NSManagedObject

@property (nonatomic, copy) NSString *account;
@property (nonatomic, copy) NSData *avatar;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *firstname;
@property (nonatomic, copy) NSString *lastname;
@property (nonatomic, strong) NSOrderedSet *transactions;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, readonly) NSImage *avatarImage;
@property (nonatomic, copy) NSSet *addresses;

- (BOOL)canBeRemoved;
- (BOOL)canEditAddresses;

@end

@interface HIContact (CoreDataGeneratedAccessors)<HIPerson>

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
