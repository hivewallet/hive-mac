//
//  BCClient.h
//  Hive
//
//  Created by Bazyli Zygan on 20.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "AFHTTPClient.h"

@protocol BCTransactionObserver;

@class HIContact;
@class HIPasswordHolder;
@class HITransaction;

extern NSString * const BCClientBitcoinjDirectory;
extern NSString * const BCClientTorDirectory;
extern NSString * const BCClientPasswordChangedNotification;

/*
 This object acts as a single gateway to BitcoinKit and Tor, handles sending bitcoins, managing wallets etc.
 */

@interface BCClient : AFHTTPClient

@property (nonatomic, readonly, getter = unreadTransactions) NSUInteger unreadTransactions;
@property (nonatomic, readonly) uint64 availableBalance;
@property (nonatomic, readonly) uint64 estimatedBalance;
@property (nonatomic, readonly) NSDate *lastWalletChangeDate;
@property (nonatomic, strong) NSString *walletHash;
@property (nonatomic, readonly, getter = isRunning) BOOL isRunning;
@property (nonatomic, assign, setter = setCheckInterval:) NSUInteger checkInterval;
@property (nonatomic, readonly, getter = isWalletPasswordProtected) BOOL walletPasswordProtected;

+ (BCClient *)sharedClient;

- (BOOL)start:(NSError **)error;
- (void)shutdown;
- (void)updateNotifications;

- (void)createWallet:(NSError **)error;
- (void)createWalletWithPassword:(HIPasswordHolder *)password
                           error:(NSError **)error;

- (void)changeWalletPassword:(HIPasswordHolder *)fromPassword
                  toPassword:(HIPasswordHolder *)toPassword
                       error:(NSError **)error;

- (void)sendBitcoins:(uint64)amount
              toHash:(NSString *)hash
            password:(HIPasswordHolder *)password
               error:(NSError **)error
          completion:(void (^)(BOOL success, NSString *transactionId))completion;

- (void)sendBitcoins:(uint64)amount
           toContact:(HIContact *)contact
            password:(HIPasswordHolder *)password
               error:(NSError **)error
          completion:(void(^)(BOOL success, NSString *transactionId))completion;

- (satoshi_t)feeWhenSendingBitcoin:(uint64)amount;

- (NSDictionary *)transactionDefinitionWithHash:(NSString *)hash;
- (void)rebuildTransactionsList;
- (void)clearTransactionsList;

- (void)addTransactionObserver:(id<BCTransactionObserver>)observer;
- (void)removeTransactionObserver:(id<BCTransactionObserver>)observer;

- (void)backupWalletToDirectory:(NSURL *)backupURL error:(NSError **)error;

@end

@protocol BCTransactionObserver<NSObject>

- (void)transactionAdded:(HITransaction *)transaction;
- (void)transactionConfirmed:(HITransaction *)transaction;

@end
