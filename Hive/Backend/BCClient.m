//
//  BCClient.m
//  Hive
//
//  Created by Bazyli Zygan on 20.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <AFNetworking/AFJSONRequestOperation.h>
#import <BitcoinJKit/BitcoinJKit.h>
// #import <Tor/Tor.h>
#import "BCClient.h"
#import "HIAppDelegate.h"
#import "HIApplication.h"
#import "HIApplicationsManager.h"
#import "HIContact.h"
#import "HIDatabaseManager.h"
#import "HIPasswordHolder.h"
#import "HITransaction.h"

static NSString * const kBCClientBaseURLString = @"https://grabhive.com/";
NSString * const BCClientBitcoinjDirectory = @"BitcoinJ.network";
NSString * const BCClientTorDirectory = @"Tor.network";
NSString * const BCClientPasswordChangedNotification = @"BCClientPasswordChangedNotification";

@interface BCClient () {
    NSManagedObjectContext *_transactionUpdateContext;
    NSDateFormatter *_dateFormatter;
}

@property (nonatomic, assign) uint64 availableBalance;
@property (nonatomic, assign) uint64 estimatedBalance;
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

- (instancetype)initWithBaseURL:(NSURL *)URL {
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
        /*[notificationCenter addObserver:self
                               selector:@selector(torStarted:)
                                   name:kHITorManagerStarted
                                 object:nil];*/
        [notificationCenter addObserver:self
                               selector:@selector(bitcoinKitStarted:)
                                   name:kHIBitcoinManagerStartedNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(transactionUpdated:)
                                   name:kHIBitcoinManagerTransactionChangedNotification
                                 object:nil];

        /*
        HITorManager *tor = [HITorManager defaultManager];
        tor.dataDirectoryURL = [self torDirectory];
        tor.port = 9999;
        */

        HIBitcoinManager *bitcoin = [HIBitcoinManager defaultManager];
        bitcoin.dataURL = [self bitcoinjDirectory];
        bitcoin.exceptionHandler = ^(NSException *exception) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [AppDelegate showExceptionWindowWithException:exception];
            });
        };

        _transactionObservers = [NSMutableSet new];

        if (DEBUG_OPTION_ENABLED(TESTING_NETWORK)) {
            bitcoin.testingNetwork = YES;
        } else {
            bitcoin.checkpointsFilePath = [[NSBundle mainBundle] pathForResource:@"bitcoinkit" ofType:@"checkpoints"];
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

/*
- (void)torStarted:(NSNotification *)notification {
    [HITorManager defaultManager].torRouting = YES;
}
*/

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
        HILogError(@"Error loading transactions: %@", error);
        return;
    }

    for (HITransaction *transaction in transactions) {
        [DBM deleteObject:transaction];
    }

    [DBM save:&error];

    if (error) {
        HILogError(@"Error deleting transactions: %@", error);
        return;
    }
}

- (void)repairTransactionsList {
    NSArray *transactions = [[HIBitcoinManager defaultManager] allTransactions];
    HILogInfo(@"Repairing %ld transactions in the database", transactions.count);

    NSMutableDictionary *knownTransactions = [NSMutableDictionary new];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HITransactionEntity];
    for (HITransaction *transaction in [_transactionUpdateContext executeFetchRequest:request
                                                                         error:NULL]) {
        knownTransactions[transaction.id] = transaction;
    }

    [_transactionUpdateContext performBlock:^{
        for (NSDictionary *transactionData in transactions) {
            HITransaction *transaction = [self repairTransaction:transactionData];
            [knownTransactions removeObjectForKey:transaction.id];
        }

        if (knownTransactions.count > 0) {
            for (HITransaction *transaction in knownTransactions.allValues) {
                HILogError(@"Deleting unknown transaction: %@", transaction);
                [_transactionUpdateContext deleteObject:transaction];
            }
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

- (HITransaction *)repairTransaction:(NSDictionary *)data {
    NSAssert(data != nil, @"Transaction data shouldn't be null");
    NSAssert(data[@"txid"] != nil, @"Transaction id shouldn't be null");

    HITransaction *transaction = [self fetchTransactionWithId:data[@"txid"]];
    if (!transaction) {
        transaction = [NSEntityDescription insertNewObjectForEntityForName:HITransactionEntity
                                                    inManagedObjectContext:_transactionUpdateContext];
    }

    [self fillTransaction:transaction fromData:data];
    [self updateStatusForTransaction:transaction fromData:data];
    return transaction;
}

- (void)transactionUpdated:(NSNotification *)notification {
    [_transactionUpdateContext performBlock:^{
        NSDictionary *transaction = notification.userInfo[@"json"];

        if (!transaction) {
            HILogError(@"Error: no transaction data for transaction %@", notification.object);
            return;
        }

        [self parseAndNotifyOfTransaction:transaction];

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

- (BOOL)hasPendingTransactions {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HITransactionEntity];
    request.predicate = [NSPredicate predicateWithFormat:@"status == %d", HITransactionStatusPending];

    NSUInteger count = [_transactionUpdateContext countForFetchRequest:request error:NULL];
    return (count > 0);
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

- (void)parseAndNotifyOfTransaction:(NSDictionary *)data {
    NSAssert(data != nil, @"Transaction data shouldn't be null");
    NSAssert(data[@"txid"] != nil, @"Transaction id shouldn't be null");

    HITransaction *transaction = [self fetchTransactionWithId:data[@"txid"]];
    BOOL alreadyExists = transaction != nil;
    if (!alreadyExists) {
        transaction = [NSEntityDescription insertNewObjectForEntityForName:HITransactionEntity
                                                    inManagedObjectContext:_transactionUpdateContext];
        [self fillTransaction:transaction fromData:data];
    }

    BOOL statusChanged = [self updateStatusForTransaction:transaction fromData:data];
    if (alreadyExists) {
        if (statusChanged) {
            [self notifyObserversWithSelector:@selector(transactionChangedStatus:) transaction:transaction];
        }
    } else {
        [self notifyObserversWithSelector:@selector(transactionAdded:) transaction:transaction];
    }
}

- (void)fillTransaction:(HITransaction *)transaction fromData:(NSDictionary *)data {
    NSAssert(!transaction.id || [data[@"txid"] isEqual:transaction.id], @"Transaction id must match");

    transaction.id = data[@"txid"];
    transaction.date = data[@"time"];
    transaction.amount = [data[@"amount"] longLongValue];
    transaction.fee = [data[@"fee"] longLongValue];

    // source address will be in inputs (though it might be nil) - we take only the first non-empty one
    NSUInteger srcIndex = [data[@"inputs"] indexOfObjectPassingTest:^BOOL(id input, NSUInteger idx, BOOL *stop) {
        return (input[@"address"] != nil);
    }];

    transaction.sourceAddress = (srcIndex != NSNotFound) ? data[@"inputs"][srcIndex][@"address"] : nil;

    NSString *contactHash;

    if (transaction.isIncoming) {
        // target address (one of ours) is the first output with type = own
        NSUInteger ownIndex = [data[@"outputs"] indexOfObjectPassingTest:^BOOL(id output, NSUInteger idx, BOOL *stop) {
            return [output[@"type"] isEqual:@"own"];
        }];

        transaction.targetAddress = (ownIndex != NSNotFound) ? data[@"outputs"][ownIndex][@"address"] : nil;

        contactHash = transaction.sourceAddress;
    } else {
        // target address is the first output with type = external
        NSUInteger extIndex = [data[@"outputs"] indexOfObjectPassingTest:^BOOL(id output, NSUInteger idx, BOOL *stop) {
            return [output[@"type"] isEqual:@"external"];
        }];

        transaction.targetAddress = (extIndex != NSNotFound) ? data[@"outputs"][extIndex][@"address"] : nil;

        contactHash = transaction.targetAddress;
    }

    if (contactHash) {
        // Try to find a contact that matches that transaction
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:HIContactEntity];
        request.predicate = [NSPredicate predicateWithFormat:@"ANY addresses.address == %@", contactHash];

        NSArray *response = [_transactionUpdateContext executeFetchRequest:request error:NULL];
        transaction.contact = response.firstObject;
    } else {
        transaction.contact = nil;
    }
}

- (BOOL)updateStatusForTransaction:(HITransaction *)transaction fromData:(NSDictionary *)data {
    NSAssert([data[@"txid"] isEqual:transaction.id], @"Transaction id must match");

    NSString *confidence = data[@"confidence"];

    HITransactionStatus previousStatus = transaction.status;
    if ([confidence isEqual:@"building"]) {
        transaction.status = HITransactionStatusBuilding;
    } else if ([confidence isEqual:@"dead"]) {
        transaction.status = HITransactionStatusDead;
    } else if ([confidence isEqual:@"pending"]) {
        transaction.status = HITransactionStatusPending;
    } else {
        transaction.status = HITransactionStatusUnknown;
    }

    BOOL statusChanged = (transaction.status != previousStatus);

    if (statusChanged) {
        HILogDebug(@"Transaction %@ is now %@ (%d)", transaction.id, confidence, transaction.status);
    }

    return statusChanged;
}

- (HITransaction *)fetchTransactionWithId:(NSString *)transactionId {
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:HITransactionEntity];
    request.predicate = [NSPredicate predicateWithFormat:@"id == %@", transactionId];
    NSArray *response = [_transactionUpdateContext executeFetchRequest:request error:NULL];
    return response.count > 0 ? response[0] : nil;
}

- (void)sendBitcoins:(uint64)amount
              toHash:(NSString *)hash
            password:(HIPasswordHolder *)password
               error:(NSError **)error
          completion:(void (^)(BOOL success, HITransaction *transaction))completion {

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

                BOOL success = (transactionId != nil);
                HILogInfo(@"Transaction %@: id = %@", success ? @"succeeded" : @"failed", transactionId);

                dispatch_async(dispatch_get_main_queue(), ^{
                    HITransaction *transaction = [self fetchTransactionWithId:transactionId];
                    completion(success, transaction);
                });
            }];
        }
    }
}

- (void)submitPaymentRequestWithSessionId:(int)sessionId
                                 password:(HIPasswordHolder *)password
                                    error:(NSError **)error
                               completion:(void (^)(NSError *error, NSDictionary *data, HITransaction *tx))completion {

    HIBitcoinManager *manager = [HIBitcoinManager defaultManager];

    [manager sendPaymentRequest:sessionId
                       password:password.data
                          error:error
                       callback:^(NSError *sendError, NSDictionary *data, NSString *transactionId) {
                           [_transactionUpdateContext performBlock:^{
                               HITransaction *transaction = [self fetchTransactionWithId:transactionId];

                               dispatch_async(dispatch_get_main_queue(), ^{
                                   completion(sendError, data, transaction);
                               });
                           }];
                       }];
}

- (void)attachSourceApplication:(HIApplication *)application toTransaction:(HITransaction *)transaction {
    HIApplication *applicationInUpdateContext = [self fetchApplicationForUpdateContext:application];
    transaction.sourceApplication = applicationInUpdateContext;
}

- (HIApplication *)fetchApplicationForUpdateContext:(HIApplication *)application {
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:HIApplicationEntity];
    request.predicate = [NSPredicate predicateWithFormat:@"id == %@", application.id];
    NSArray *response = [_transactionUpdateContext executeFetchRequest:request error:NULL];
    return response.count > 0 ? response[0] : nil;
}

- (void)updateTransaction:(HITransaction *)transaction {
    [_transactionUpdateContext performBlock:^{
        NSError *error = nil;
        [_transactionUpdateContext save:&error];

        if (error) {
            HILogError(@"Error saving transaction: %@", error);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error = nil;
            [DBM save:&error];

            if (error) {
                HILogError(@"Error saving updated transactions: %@", error);
            } else {
                [self notifyObserversWithSelector:@selector(transactionMetadataWasUpdated:) transaction:transaction];
            }
        });
    }];
}

- (satoshi_t)feeWhenSendingBitcoin:(uint64)amount
                       toRecipient:(NSString *)recipient
                             error:(NSError **)error {
    return [[HIBitcoinManager defaultManager] calculateTransactionFeeForSendingCoins:amount
                                                                         toRecipient:recipient
                                                                               error:error];
}

- (void)addTransactionObserver:(id <BCTransactionObserver>)observer {
    [self.transactionObservers addObject:observer];
}

- (void)removeTransactionObserver:(id <BCTransactionObserver>)observer {
    [self.transactionObservers removeObject:observer];
}

- (void)notifyObserversWithSelector:(SEL)selector transaction:(HITransaction *)transaction {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<BCTransactionObserver> observer in self.transactionObservers) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            if ([observer respondsToSelector:selector]) {
                [observer performSelector:selector withObject:transaction];
            }
            #pragma clang diagnostic pop
        }
    });
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
