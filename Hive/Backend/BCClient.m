//
//  BCClient.m
//  Hive
//
//  Created by Bazyli Zygan on 20.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <AFNetworking/AFJSONRequestOperation.h>
#import <BitcoinJKit/BitcoinJKit.h>
#import <Tor/Tor.h>
#import "BCClient.h"
#import "HIAppDelegate.h"
#import "HIApplicationsManager.h"
#import "HIContact.h"
#import "HIDatabaseManager.h"
#import "HITransaction.h"
#import "HIPasswordHolder.h"

static NSString * const kBCClientBaseURLString = @"https://grabhive.com/";
NSString * const BCClientBitcoinjDirectory = @"BitcoinJ.network";
NSString * const BCClientTorDirectory = @"Tor.network";
NSString * const BCClientPasswordChangedNotification = @"BCClientPasswordChangedNotification";

@interface BCClient () {
    NSManagedObjectContext *_transactionUpdateContext;
    NSDateFormatter *_dateFormatter;
}

@property (nonatomic) uint64 availableBalance;
@property (nonatomic) uint64 estimatedBalance;
@property (nonatomic, strong, readonly) NSMutableSet *transactionObservers;

@end

@implementation BCClient

+ (BCClient *)sharedClient {
    static BCClient *sharedClient = nil;
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:kBCClientBaseURLString]];
    });

    return sharedClient;
}

- (id)initWithBaseURL:(NSURL *)URL {
    self = [super initWithBaseURL:URL];

    if (self) {
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];

        _checkInterval = 10;
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ssz";

        NSManagedObjectContext *mainContext = DBM;
        if (!mainContext) {
            HILogError(@"No main managed object context?!");
            return nil;
        }

        _transactionUpdateContext = [[NSManagedObjectContext alloc]
                                     initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _transactionUpdateContext.parentContext = mainContext;

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(torStarted:)
                                   name:kHITorManagerStarted
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(bitcoinKitStarted:)
                                   name:kHIBitcoinManagerStartedNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(transactionUpdated:)
                                   name:kHIBitcoinManagerTransactionChangedNotification
                                 object:nil];

        HITorManager *tor = [HITorManager defaultManager];
        tor.dataDirectoryURL = [self torDirectory];
        tor.port = 9999;

        HIBitcoinManager *bitcoin = [HIBitcoinManager defaultManager];
        bitcoin.dataURL = [self bitcoinjDirectory];
        bitcoin.exceptionHandler = ^(NSException *exception) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSApp delegate] showExceptionWindowWithException:exception];
            });
        };

        _transactionObservers = [NSMutableSet new];

        if (DEBUG_OPTION_ENABLED(TESTING_NETWORK)) {
            bitcoin.testingNetwork = YES;
        }

        [bitcoin addObserver:self
                  forKeyPath:@"availableBalance"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:NULL];
        [bitcoin addObserver:self
                  forKeyPath:@"estimatedBalance"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:NULL];
        [bitcoin addObserver:self
                  forKeyPath:@"syncProgress"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:NULL];
        [bitcoin addObserver:self
                  forKeyPath:@"connections"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:NULL];
    }

    return self;
}

- (BOOL)start:(NSError **)error {

    // TOR disabled for now
    // [tor start];

    *error = nil;

    if ([[HIBitcoinManager defaultManager] start:error]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        self.availableBalance = [[defaults objectForKey:@"LastBalance"] unsignedLongLongValue];
        self.estimatedBalance = [[defaults objectForKey:@"LastEstimatedBalance"] unsignedLongLongValue];

        [self updateNotifications];
    }

    return !*error;
}

- (void)createWallet:(NSError **)error {
    HILogInfo(@"Creating new wallet...");
    [[HIBitcoinManager defaultManager] createWallet:error];
}

- (void)createWalletWithPassword:(HIPasswordHolder *)password
                           error:(NSError **)error {
    HILogInfo(@"Creating new protected wallet...");
    [[HIBitcoinManager defaultManager] createWalletWithPassword:password.data error:error];
}

- (void)changeWalletPassword:(HIPasswordHolder *)fromPassword
                  toPassword:(HIPasswordHolder *)toPassword
                       error:(NSError **)error {
    HILogInfo(@"Changing wallet password...");
    [[HIBitcoinManager defaultManager] changeWalletPassword:fromPassword.data
                                                 toPassword:toPassword.data
                                                      error:error];

    if (!(error && *error)) {
        [[NSNotificationCenter defaultCenter] postNotificationName:BCClientPasswordChangedNotification object:self];
    }
}

- (void)torStarted:(NSNotification *)notification {
    [HITorManager defaultManager].torRouting = YES;
}

- (void)bitcoinKitStarted:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self willChangeValueForKey:@"isRunning"];
        [self didChangeValueForKey:@"isRunning"];

        [self willChangeValueForKey:@"walletHash"];
        _walletHash = [HIBitcoinManager defaultManager].walletAddress;
        [self didChangeValueForKey:@"walletHash"];
    });
}

- (void)clearTransactionsList {
    NSError *error = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HITransactionEntity];
    NSArray *transactions = [DBM executeFetchRequest:request error:&error];

    HILogInfo(@"Clearing transaction list");

    if (error) {
        HILogError(@"%@: Error loading transactions: %@", NSStringFromSelector(_cmd), error);
        return;
    }

    for (HITransaction *transaction in transactions) {
        [DBM deleteObject:transaction];
    }

    [DBM save:&error];

    if (error) {
        HILogError(@"%@: Error deleting transactions: %@", NSStringFromSelector(_cmd), error);
        return;
    }
}

- (void)rebuildTransactionsList {
    NSArray *transactions = [[HIBitcoinManager defaultManager] allTransactions];

    HILogInfo(@"Adding %ld transactions to database", transactions.count);

    [_transactionUpdateContext performBlock:^{
        for (NSDictionary *transaction in transactions) {
            [self parseTransaction:transaction notify:YES];
        }

        NSError *error = nil;
        [_transactionUpdateContext save:&error];

        if (error) {
            HILogError(@"Error saving updated transactions: %@", error);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error = nil;
            [DBM save:&error];

            if (error) {
                HILogError(@"Error saving updated transactions: %@", error);
            }

            [self updateNotifications];
        });
    }];
}

- (void)transactionUpdated:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *transaction = [[HIBitcoinManager defaultManager] transactionForHash:notification.object];

        if (!transaction) {
            HILogError(@"Error: transactionUpdated: no such transaction %@", notification.object);
            return;
        }

        [_transactionUpdateContext performBlock:^{
            [self parseTransaction:transaction notify:YES];

            NSError *error = nil;
            [_transactionUpdateContext save:&error];

            if (!error) {
                HILogInfo(@"Saved transaction %@", transaction[@"txid"]);
            } else {
                HILogError(@"Error saving transaction %@: %@", transaction[@"txid"], error);
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = nil;
                [DBM save:&error];

                if (error) {
                    HILogError(@"Error saving transaction %@: %@", transaction[@"txid"], error);
                }

                [self updateNotifications];
            });
        }];
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (object == [HIBitcoinManager defaultManager]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        if ([keyPath isEqual:@"availableBalance"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.availableBalance = [object availableBalance];
                [defaults setObject:@(self.availableBalance) forKey:@"LastBalance"];
            });
        } else if ([keyPath isEqual:@"estimatedBalance"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.estimatedBalance = [object estimatedBalance];
                [defaults setObject:@(self.estimatedBalance) forKey:@"LastEstimatedBalance"];
            });
        }
    }
}

- (void)shutdown {
    [[HIBitcoinManager defaultManager] stop];
    // [[HITorManager defaultManager] stop];
}

- (void)dealloc {
    [self shutdown];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    @try {
        HIBitcoinManager *manager = [HIBitcoinManager defaultManager];

        [manager removeObserver:self forKeyPath:@"connections"];
        [manager removeObserver:self forKeyPath:@"availableBalance"];
        [manager removeObserver:self forKeyPath:@"estimatedBalance"];
        [manager removeObserver:self forKeyPath:@"syncProgress"];
    }
    @catch (NSException *exception) {
        // there should be a way to check if I'm added as observer before calling remove but I don't know any...
        HILogError(@"Dealloc failed: %@", exception);
    }
}

- (NSURL *)bitcoinjDirectory {
    NSURL *appSupportURL = [(HIAppDelegate *) [NSApp delegate] applicationFilesDirectory];
    return [appSupportURL URLByAppendingPathComponent:BCClientBitcoinjDirectory];
}

- (NSURL *)torDirectory {
    NSURL *appSupportURL = [(HIAppDelegate *) [NSApp delegate] applicationFilesDirectory];
    return [appSupportURL URLByAppendingPathComponent:BCClientTorDirectory];
}

- (BOOL)isRunning {
    return [HIBitcoinManager defaultManager].isRunning;
}

- (NSDate *)lastWalletChangeDate {
    return [[HIBitcoinManager defaultManager] lastWalletChangeDate];
}

- (void)setCheckInterval:(NSUInteger)checkInterval {
    if (checkInterval == 0) {
        return;
    }
    
    _checkInterval = checkInterval;
}


- (NSUInteger)unreadTransactions {
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:HITransactionEntity];
    req.predicate = [NSPredicate predicateWithFormat:@"read == NO"];
    
    return [_transactionUpdateContext countForFetchRequest:req error:NULL];
}

- (void)updateNotifications {
    [self willChangeValueForKey:@"unreadTransactions"];
    
    if (self.unreadTransactions > 0) {
        [[NSApp dockTile] setBadgeLabel:[NSString stringWithFormat:@"%lu", self.unreadTransactions]];
        [NSApp requestUserAttention:NSInformationalRequest];
    } else {
        [[NSApp dockTile] setBadgeLabel:@""];
    }

    [self didChangeValueForKey:@"unreadTransactions"];
}

- (NSDictionary *)transactionDefinitionWithHash:(NSString *)hash {
    return [[HIBitcoinManager defaultManager] transactionForHash:hash];
}

- (void)parseTransaction:(NSDictionary *)data notify:(BOOL)notify {
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:HITransactionEntity];
    request.predicate = [NSPredicate predicateWithFormat:@"id == %@", data[@"txid"]];

    HITransaction *transaction;
    NSArray *response = [_transactionUpdateContext executeFetchRequest:request error:NULL];

    BOOL alreadyExists = response.count > 0;
    if (alreadyExists) {
        transaction = response[0];
    } else {
        transaction = [NSEntityDescription insertNewObjectForEntityForName:HITransactionEntity
                                                    inManagedObjectContext:_transactionUpdateContext];

        transaction.id = data[@"txid"];
        transaction.date = data[@"time"];
        transaction.amount = [data[@"amount"] longLongValue];
        transaction.request = (![data[@"details"][0][@"category"] isEqual:@"send"]);

        if (!notify) {
            transaction.read = YES;
        }

        transaction.senderHash = data[@"details"][0][@"address"];

        if (transaction.senderHash) {
            // Try to find a contact that matches that transaction
            NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:HIContactEntity];
            request.predicate = [NSPredicate predicateWithFormat:@"ANY addresses.address == %@",
                                 transaction.senderHash];

            NSArray *response = [_transactionUpdateContext executeFetchRequest:request error:NULL];

            if (response.count > 0) {
                HIContact *contact = response[0];
                transaction.senderName = [NSString stringWithFormat:@"%@ %@", contact.firstname, contact.lastname];
                transaction.senderEmail = contact.email;
                transaction.contact = contact;
            }
        }
    }

    NSString *confidence = data[@"confidence"];

    if ([confidence isEqual:@"building"]) {
        transaction.status = HITransactionStatusBuilding;
    } else if ([confidence isEqual:@"dead"]) {
        transaction.status = HITransactionStatusDead;
    } else if ([confidence isEqual:@"pending"]) {
        transaction.status = HITransactionStatusPending;
    } else {
        transaction.status = HITransactionStatusUnknown;
    }

    if (!alreadyExists) {
        for (id<BCTransactionObserver> observer in self.transactionObservers) {
            [observer transactionAdded:transaction];
        }
    }
}


- (void)sendBitcoins:(uint64)amount
              toHash:(NSString *)hash
            password:(HIPasswordHolder *)password
               error:(NSError **)error
          completion:(void (^)(BOOL success, NSString *transactionId))completion {

    HILogInfo(@"Sending %lld satoshi to %@ (%@ password)", amount, hash, password ? @"with" : @"no");

    if (amount > self.availableBalance) {
        HILogWarn(@"Not enough balance: only %lld satoshi available", self.availableBalance);
        completion(NO, nil);
    } else {
        HIBitcoinManager *bitcoin = [HIBitcoinManager defaultManager];

        // Sanity check first
        if (amount <= 0 || bitcoin.availableBalance < amount || ![bitcoin isAddressValid:hash]) {
            if (amount <= 0 || amount > bitcoin.availableBalance) {
                HILogError(@"Sanity check failed: only %lld satoshi available, amount = %lld",
                           self.availableBalance, amount);
            }

            if (![bitcoin isAddressValid:hash]) {
                HILogError(@"Sanity check failed: address %@ is invalid", hash);
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, nil);
            });
        } else {
            [bitcoin sendCoins:amount
                   toRecipient:hash
                       comment:nil
                      password:password.data
                         error:error
                    completion:^(NSString *transactionId) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    HILogInfo(@"Transaction %@: id = %@", transactionId ? @"succeeded" : @"failed", transactionId);
                    completion((transactionId != nil), transactionId);
                });
            }];
        }
    }
}

- (void)sendBitcoins:(uint64)amount
           toContact:(HIContact *)contact
            password:(HIPasswordHolder *)password
               error:(NSError **)error
          completion:(void(^)(BOOL success, NSString *transactionId))completion {
    [self sendBitcoins:amount toHash:contact.account password:password error:error completion:completion];
}

- (satoshi_t)feeWhenSendingBitcoin:(uint64)amount {
    return amount > 0 ? [[HIBitcoinManager defaultManager] calculateTransactionFeeForSendingCoins:amount] : 0;
}

- (void)addTransactionObserver:(id <BCTransactionObserver>)observer {
    [self.transactionObservers addObject:observer];
}

- (void)removeTransactionObserver:(id <BCTransactionObserver>)observer {
    [self.transactionObservers removeObject:observer];
}

- (void)backupWalletToDirectory:(NSURL *)backupURL error:(NSError **)error {
    NSURL *backupFileURL = [backupURL URLByAppendingPathComponent:@"bitcoinkit.wallet"];
    HILogInfo(@"Backing up wallet file to %@", backupFileURL);
    return [[HIBitcoinManager defaultManager] exportWalletTo:backupFileURL error:error];
}

- (BOOL)isWalletPasswordProtected {
    return [HIBitcoinManager defaultManager].isWalletEncrypted;
}

@end
