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
#import "HITransaction.h"

static NSString * const kBCClientBaseURLString = @"https://grabhive.com/";

@interface BCClient ()
{
    NSManagedObjectContext *_transactionUpdateContext;
    NSDateFormatter *_dateFormatter;
    AFHTTPRequestOperation *_exchangeRateOperation;
}

@property (nonatomic) uint64 balance;

@end

@implementation BCClient

+ (BCClient *)sharedClient
{
    static BCClient *_sharedClient = nil;
    static dispatch_once_t oncePredicate;

    if (!_sharedClient)
    {
        dispatch_once(&oncePredicate, ^{
            _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:kBCClientBaseURLString]];
        });
    }

    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (self)
    {
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];

        _checkInterval = 10;
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ssz";

        _transactionUpdateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _transactionUpdateContext.parentContext = [(HIAppDelegate *) [NSApp delegate] managedObjectContext];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(torStarted:)
                                                     name:kHITorManagerStarted
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(bitcoinKitStarted:)
                                                     name:kHIBitcoinManagerStartedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(transactionUpdated:)
                                                     name:kHIBitcoinManagerTransactionChangedNotification
                                                   object:nil];

        [HIBitcoinManager defaultManager].dataURL = [self bitcoindDirectory];
        [HITorManager defaultManager].dataDirectoryURL = [self torDirectory];
        [HITorManager defaultManager].port = 9999;
        
#ifdef TESTING_NETWORK
        [HIBitcoinManager defaultManager].testingNetwork = YES;
#endif //TESTING_NETWORK
        
        // Register to all values changing
        [[HIBitcoinManager defaultManager] addObserver:self
                                            forKeyPath:@"balance"
                                               options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                               context:NULL];
        [[HIBitcoinManager defaultManager] addObserver:self
                                            forKeyPath:@"syncProgress"
                                               options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                               context:NULL];
        [[HIBitcoinManager defaultManager] addObserver:self
                                            forKeyPath:@"connections"
                                               options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                               context:NULL];

        // TOR disabled for now
        // [[HITorManager defaultManager] start];

        [[HIBitcoinManager defaultManager] start];

        self.balance = [[[NSUserDefaults standardUserDefaults] objectForKey:@"LastBalance"] unsignedLongLongValue];

        [self updateNotifications];
    }

    return self;
}

- (void)torStarted:(NSNotification *)not
{
    [HITorManager defaultManager].torRouting = YES;
}

- (void)bitcoinKitStarted:(NSNotification *)not
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self willChangeValueForKey:@"isRunning"];
        [self didChangeValueForKey:@"isRunning"];

        [self willChangeValueForKey:@"walletHash"];
        _walletHash = [HIBitcoinManager defaultManager].walletAddress;
        [self didChangeValueForKey:@"walletHash"];

        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"FirstRun"])
        {
            NSArray *transactions = [HIBitcoinManager defaultManager].allTransactions;
            [_transactionUpdateContext performBlock:^{
                // We need to scan whole wallet in search for transactions
                for (NSDictionary *transaction in transactions)
                {
                    [self parseTransaction:transaction notify:YES];
                }

                [_transactionUpdateContext save:NULL];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateNotifications];
                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"FirstRun"];
                });
            }];
        }
    });
}

- (void)transactionUpdated:(NSNotification *)not
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *trans = [[HIBitcoinManager defaultManager] transactionForHash:not.object];
        [_transactionUpdateContext performBlock:^{
            [self parseTransaction:trans notify:YES];
            [_transactionUpdateContext save:NULL];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateNotifications];
            });
        }];
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == [HIBitcoinManager defaultManager])
    {
        if ([keyPath compare:@"balance"] == NSOrderedSame)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.balance = [HIBitcoinManager defaultManager].balance;

                [[NSUserDefaults standardUserDefaults] setObject:@(self.balance) forKey:@"LastBalance"];
            });
        }
        else if ([keyPath compare:@"syncProgress"] == NSOrderedSame)
        {
        }
        else if([keyPath compare:@"connections"] == NSOrderedSame)
        {
        }
    }
}

- (void)shutdown
{
    [[HIBitcoinManager defaultManager] stop];
    [[HITorManager defaultManager] stop];
}

- (void)dealloc
{
    [self shutdown];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[HIBitcoinManager defaultManager] removeObserver:self forKeyPath:@"connections"];
    [[HIBitcoinManager defaultManager] removeObserver:self forKeyPath:@"balance"];
    [[HIBitcoinManager defaultManager] removeObserver:self forKeyPath:@"syncProgress"];
    
}

- (NSURL *)bitcoindDirectory
{
    NSURL *appSupportURL = [(HIAppDelegate *) [NSApp delegate] applicationFilesDirectory];
    return [appSupportURL URLByAppendingPathComponent:@"BitcoinJ.network"];
}

- (NSURL *)torDirectory
{
    NSURL *appSupportURL = [(HIAppDelegate *) [NSApp delegate] applicationFilesDirectory];
    return [appSupportURL URLByAppendingPathComponent:@"Tor.network"];
}

- (BOOL)isRunning
{
    return [HIBitcoinManager defaultManager].isRunning;
}

- (void)setCheckInterval:(NSUInteger)checkInterval
{
    if (checkInterval == 0)
    {
        return;
    }
    
    _checkInterval = checkInterval;
}


- (NSUInteger)unreadTransactions
{
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:HITransactionEntity];
    req.predicate = [NSPredicate predicateWithFormat:@"read == NO"];
    
    return [_transactionUpdateContext countForFetchRequest:req error:NULL];
}

- (void)updateNotifications
{
    [self willChangeValueForKey:@"unreadTransactions"];
    
    if (self.unreadTransactions > 0)
    {
        [[NSApp dockTile] setBadgeLabel:[NSString stringWithFormat:@"%lu", self.unreadTransactions]];
        [NSApp requestUserAttention:NSInformationalRequest];
    }
    else
    {
        [[NSApp dockTile] setBadgeLabel:@""];
    }

    [self didChangeValueForKey:@"unreadTransactions"];
}

- (NSDictionary *)transactionDefinitionWithHash:(NSString *)hash
{
    return [[HIBitcoinManager defaultManager] transactionForHash:hash];
}

- (BOOL)parseTransaction:(NSDictionary *)t notify:(BOOL)notify
{
    BOOL continueFetching = YES;

    NSFetchRequest *req = [[NSFetchRequest alloc] initWithEntityName:HITransactionEntity];
    req.predicate = [NSPredicate predicateWithFormat:@"id == %@", t[@"txid"]];
    NSArray *resp = [_transactionUpdateContext executeFetchRequest:req error:NULL];

    if (resp.count > 0)
    {
        HITransaction *trans = resp[0];
        
        if (trans.confirmations != [t[@"confirmations"] intValue])
        {
            trans.confirmations = [t[@"confirmations"] intValue];
        }
        else
        {
            continueFetching = NO;
        }
    }
    else
    {
        HITransaction *trans = [NSEntityDescription
                                insertNewObjectForEntityForName:HITransactionEntity
                                inManagedObjectContext:_transactionUpdateContext];

        trans.id = t[@"txid"];
        trans.date = [t[@"time"] timeIntervalSince1970];
        trans.amount = [t[@"amount"] longLongValue];
        trans.request = ([(NSString *)t[@"details"][0][@"category"] compare:@"send"] != NSOrderedSame);
        trans.confirmations = [t[@"confirmations"] intValue];

        if (!notify)
        {
            trans.read = YES;
        }

        trans.senderHash = t[@"details"][0][@"address"];
        
        if (trans.senderHash)
        {
            // Try to find a contact that matches that transaction
            NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:HIContactEntity];
            request.predicate = [NSPredicate predicateWithFormat:@"ANY addresses.address == %@", trans.senderHash];
            NSArray *response = [_transactionUpdateContext executeFetchRequest:request error:NULL];

            if (response.count > 0)
            {
                HIContact *contact = response[0];
                trans.senderName = [NSString stringWithFormat:@"%@ %@", contact.firstname, contact.lastname];
                trans.senderEmail = contact.email;
                trans.contact = contact;
            }
        }        
    }
    
    return continueFetching;
}


- (void)sendBitcoins:(uint64)amount
              toHash:(NSString *)hash
          completion:(void(^)(BOOL success, NSString *transactionId))completion
{
    if (amount > self.balance)
    {
        completion(NO, nil);
    }
    else
    {
        // Sanity check first
        if (amount <= 0 ||
            [[HIBitcoinManager defaultManager] balance] < amount ||
            ![[HIBitcoinManager defaultManager] isAddressValid:hash])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, nil);
            });
        }
        else
        {
            [[HIBitcoinManager defaultManager] sendCoins:amount
                                             toReceipent:hash
                                                 comment:nil
                                              completion:^(NSString *transactionId) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion((transactionId != nil), transactionId);
                });
            }];
        }
    }
}

- (void)sendBitcoins:(uint64)amount
           toContact:(HIContact *)contact
          completion:(void(^)(BOOL success, NSString *transactionId))completion
{
    [self sendBitcoins:amount toHash:contact.account completion:completion];
}

- (BOOL)backupWalletAtURL:(NSURL *)backupURL
{
    return [[HIBitcoinManager defaultManager] exportWalletTo:backupURL];
}

- (BOOL)importWalletFromURL:(NSURL *)walletURL
{
    return [[HIBitcoinManager defaultManager] importWalletFrom:walletURL];
}

- (void)exchangeRateFor:(uint64)amount forCurrency:(NSString *)currency completion:(void(^)(uint64 value))completion
{
    if (_exchangeRateOperation)
    {
        [_exchangeRateOperation cancel];
        _exchangeRateOperation = nil;
    }

    NSURL *URL = [NSURL URLWithString:
                  [NSString stringWithFormat:@"http://data.mtgox.com/api/1/BTC%@/ticker_fast", currency]];
    _exchangeRateOperation = [self HTTPRequestOperationWithRequest:[NSURLRequest requestWithURL:URL]
                                                           success:^(AFHTTPRequestOperation *operation, id response) {
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:response options:0 error:NULL];
        uint64 exchange = [resp[@"return"][@"sell"][@"value_int"] longLongValue];
        _exchangeRateOperation = nil;        
        completion(amount * exchange * 10000000.0);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        _exchangeRateOperation = nil;
    }];

    [self.operationQueue addOperation:_exchangeRateOperation];
}

@end
