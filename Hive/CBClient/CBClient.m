//
//  CBClient.m
//  Hive
//
//  Created by Bazyli Zygan on 14.06.2013.
//  Copyright (c) 2013 Nova Project. All rights reserved.
//

#import <NXOAuth2Client/NXOAuth2AccountStore.h>
#import <NXOAuth2Client/NXOAuth2Account.h>
#import <NXOAuth2Client/NXOAuth2AccessToken.h>
#import <AFNetworking/AFJSONRequestOperation.h>
#import <FXKeychain/FXKeychain.h>
#import "CBClient.h"
#import "NPContact.h"
#import "NPTransaction.h"
#import "NPAppDelegate.h"

NSString * const kCBClientLoginSuccessNotification = @"kCBClientLoginSuccessNotification";
NSString * const kCBClientLogoutNotification = @"kCBClientLogoutNotification";
NSString * const kCBClientLoginFailureNotification = @"kCBClientLoginFailureNotification";


static NSString * const kCBClientIDString = @"dc2f8a15803f03156db9ddaa8d0c0c997506fb6f196d2138e836cbc839df2549";
static NSString * const kCBClientSecrectString = @"fc3aaa711abd6e31e2e9cde128fb653183047db4eae156c52724598b3649a1c5";

static NSString * const kCBClientBaseURLString = @"https://www.coinbase.com";
static NSString * const kCBClientAuthorizeURLString = @"https://coinbase.com/oauth/authorize";
static NSString * const kCBClientTokenURLString = @"https://coinbase.com/oauth/token";
static NSString * const kCBClientRedirectURLString = @"https://coinbase.com/callback";

//static NSString * const kCBClientMtGOXExchangeURLString = @"http://data.mtgox.com/api/1/BTCUSD/trades/fetch";

@interface CBClient ()
{
    NSManagedObjectContext *_transactionUpdateContext;
    NXOAuth2Account *_account;
    NSTimer *_checkTimer;
    NSDateFormatter *_dateFormatter;
    AFHTTPRequestOperation *_currencyFetchOperation;
}

- (void)kickCheckTimer;
- (void)checkTimerCallback:(NSTimer *)timer;
- (BOOL)parseTransaction:(NSDictionary *)transaction notify:(BOOL)notify;
- (void)loginSuccess:(NSNotification *)not;
- (void)loginFailed:(NSNotification *)not;
@end

@implementation CBClient

+ (CBClient *)sharedClient
{
    static CBClient *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    if (!_sharedClient)
        dispatch_once(&oncePredicate, ^{
            _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:kCBClientBaseURLString]];
        });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (self)
    {
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        _checkInterval = 60;
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ssz";
        _transactionUpdateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _transactionUpdateContext.parentContext = [(NPAppDelegate *)[[NSApplication sharedApplication] delegate] managedObjectContext];
        [[NXOAuth2AccountStore sharedStore] setClientID:kCBClientIDString
                                                 secret:kCBClientSecrectString
                                       authorizationURL:[NSURL URLWithString:kCBClientAuthorizeURLString]
                                               tokenURL:[NSURL URLWithString:kCBClientTokenURLString]
                                            redirectURL:[NSURL URLWithString:kCBClientRedirectURLString]
                                         forAccountType:@"CoinBase"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSuccess:) name:NXOAuth2AccountStoreAccountsDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFailed:) name:NXOAuth2AccountStoreDidFailToRequestAccessNotification object:nil];
        
        self.username = [[FXKeychain defaultKeychain] objectForKey:@"CoinbaseEmail"];
        self.password = [[FXKeychain defaultKeychain] objectForKey:@"CoinbasePwd"];

        [self updateNofications];
        if (_username && _password)
        {
            [self performLogin];
        }
    }
    return self;
}

- (void)loginSuccess:(NSNotification *)not
{
  _account = not.userInfo[NXOAuth2AccountStoreNewAccountUserInfoKey];
  [[FXKeychain defaultKeychain] setObject:_username forKey:@"CoinbaseEmail"];
  [[FXKeychain defaultKeychain] setObject:_password forKey:@"CoinbasePwd"];
  [[NSNotificationCenter defaultCenter] postNotificationName:kCBClientLoginSuccessNotification object:nil];
  [self getPath:@"/api/v1/addresses" parameters:@{@"access_token": _account.accessToken.accessToken} success:^(AFHTTPRequestOperation *operation, id responseObject) {
      NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:NULL];
      if ([resp[@"addresses"] count] > 0)
      {
          [self willChangeValueForKey:@"walletHash"];
          _walletHash = [resp[@"addresses"][0][@"address"][@"address"] copy];
          [self didChangeValueForKey:@"walletHash"];
      }
  } failure:nil];

  [self kickCheckTimer];
}

- (void)loginFailed:(NSNotification *)not
{
    NSError *error = [not.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kCBClientLoginFailureNotification object:error];
}


- (BOOL)isLogged
{
    return (_account != nil);
}

- (void)performLogin
{
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"CoinBase"
                                                              username:_username
                                                              password:_password];

}

- (void)performLogout
{
//    [[NXOAuth2AccountStore sharedStore] removeAccount:_account];
    [[FXKeychain defaultKeychain] removeObjectForKey:@"CoinbaseEmail"];
    [[FXKeychain defaultKeychain] removeObjectForKey:@"CoinbasePwd"];
    self.password = nil;
    self.username = nil;
    _account = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:kCBClientLogoutNotification object:nil];
}

- (void)setCheckInterval:(NSUInteger)checkInterval
{
    if (checkInterval == 0)
        return;
    
    _checkInterval = checkInterval;
}

- (void)kickCheckTimer
{
    [_checkTimer invalidate];
    [self checkTimerCallback:nil];
    _checkTimer = [NSTimer scheduledTimerWithTimeInterval:_checkInterval target:self selector:@selector(checkTimerCallback:) userInfo:nil repeats:YES];
}

- (NSUInteger)unreadTransactions
{
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"NPTransaction"];
    req.predicate = [NSPredicate predicateWithFormat:@"read == NO"];
    
    return [_transactionUpdateContext countForFetchRequest:req error:NULL];
}

- (void)updateNofications
{
    [self willChangeValueForKey:@"unreadTransactions"];
    
    if (self.unreadTransactions > 0)
    {
        [[NSApp dockTile] setBadgeLabel:[NSString stringWithFormat:@"%lu", self.unreadTransactions]];
        [[NSApp dockTile] setShowsApplicationBadge:YES];
        [NSApp requestUserAttention:NSInformationalRequest];
    }
    else
    {
        [[NSApp dockTile] setBadgeLabel:@""];
        [[NSApp dockTile] setShowsApplicationBadge:NO];
    }
    [self didChangeValueForKey:@"unreadTransactions"];
}

- (BOOL)parseTransaction:(NSDictionary *)t notify:(BOOL)notify
{
    BOOL continueFetching = YES;
    NSFetchRequest *req = [[NSFetchRequest alloc] initWithEntityName:@"NPTransaction"];
    req.predicate = [NSPredicate predicateWithFormat:@"id == %@", t[@"id"]];
    NSArray *resp = [_transactionUpdateContext executeFetchRequest:req error:NULL];
    if (resp.count > 0)
    {
        continueFetching = NO;
    }
    else
    {
        
        NPTransaction *trans = [NSEntityDescription
                                insertNewObjectForEntityForName:@"NPTransaction"
                                inManagedObjectContext:_transactionUpdateContext];
        trans.id = t[@"id"];
        trans.date = [[_dateFormatter dateFromString:t[@"created_at"]] timeIntervalSince1970];
        trans.amount = [t[@"amount"][@"amount"] doubleValue];
        trans.request = [t[@"request"] boolValue];
//        if ([(NSString *)t[@"status"] compare:@"pending"] == NSOrderedSame)
//        {
//            trans.status = TRANSACTION_STATUS_PENDING;
//        }
//        else
//        {
//            trans.status = TRANSACTION_STATUS_COMPLETE;
//        }
        NSDictionary  *sender = nil;
        NSString *senderHash = nil;
        if (!notify)
            trans.read = YES;
        
        if (trans.request)
        {
            sender = t[@"recipient"];
            senderHash = t[@"recipient_hash"];
        }
        else
        {
            sender = t[@"sender"];
            senderHash = t[@"sender_hash"];
        }
        
        if (sender)
        {
            trans.senderEmail = sender[@"email"];
            trans.senderHash = sender[@"id"];
            trans.senderName = sender[@"name"];
        }
        else if (senderHash)
        {
            trans.senderHash = senderHash;
        }
        
        if (trans.senderHash)
        {
            // Try to find a contact that matches that transaction
            NSFetchRequest *req = [[NSFetchRequest alloc] initWithEntityName:@"NPContact"];
            req.predicate = [NSPredicate predicateWithFormat:@"account == %@", trans.senderHash];
            NSArray *resp = [_transactionUpdateContext executeFetchRequest:req error:NULL];
            if (resp.count > 0)
            {
                NPContact *c = resp[0];
                trans.senderName = [NSString stringWithFormat:@"%@ %@", c.firstname, c.lastname];
                trans.senderEmail = c.email;
                trans.contact = c;
            }
        }
        [NSApp requestUserAttention:NSInformationalRequest];
    }

    return continueFetching;
}

- (void)checkTransactionPage:(NSUInteger)page
{
    [self getPath:@"/api/v1/transactions" parameters:@{@"access_token": _account.accessToken.accessToken, @"page": [NSNumber numberWithUnsignedInteger:page]}
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:NULL];
              
              if (_balance != [resp[@"balance"][@"amount"] doubleValue])
              {
                  [self willChangeValueForKey:@"balance"];
                  _balance = [resp[@"balance"][@"amount"] doubleValue];
                  [self didChangeValueForKey:@"balance"];
              }
              [_transactionUpdateContext performBlock:^{
                  BOOL continueFetching = YES;
                  
                  for (NSDictionary *transaction in resp[@"transactions"])
                  {
                      NSDictionary *t = transaction[@"transaction"];
                      continueFetching = [self parseTransaction:t notify:YES];
                  }
                  
                  if (continueFetching && page < [resp[@"num_pages"] integerValue])
                  {
                      dispatch_async(dispatch_get_main_queue(), ^{
                          [self checkTransactionPage:page+1];
                      });
                  }
                  else
                  {
                      if (continueFetching)
                          [self updateNofications];
                  }
                  [_transactionUpdateContext save:NULL];
              }];

          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Failed to download transaction page %lu %@", page, error);
          }];
}

- (void)checkTimerCallback:(NSTimer *)timer
{
    if (!_account)
        return;
    
    [self checkTransactionPage:1];
}

- (void)sendBitcoins:(CGFloat)amount toContact:(NPContact *)contact completion:(void(^)(BOOL success))completion
{
    if (contact.account.length == 0)
    {
        completion(NO);
        return;
    }
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[self.baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"/api/v1/transactions/send_money?access_token=%@", _account.accessToken.accessToken]]];
    NSDictionary *sendingData = @{@"to": contact.account, @"amount": [NSString stringWithFormat:@"%f", amount]};
    NSLog(@"Sending body: %@", sendingData);
    [req setHTTPMethod:@"PUT"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setHTTPBody:[NSJSONSerialization dataWithJSONObject:sendingData options:0 error:NULL]];
    AFHTTPRequestOperation *op = [self HTTPRequestOperationWithRequest:req success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:NULL];
        NSLog(@"Response object %@", resp);
        
        if ([resp[@"success"] boolValue])
        {
            [self parseTransaction:resp[@"transaction"] notify:NO];
        }
        completion([resp[@"success"] boolValue]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed sending money %@", error);
        completion(NO);
    }];

    [self.operationQueue addOperation:op];
}

@end
