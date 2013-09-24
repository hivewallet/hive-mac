//
//  CBClient.h
//  Hive
//
//  Created by Bazyli Zygan on 14.06.2013.
//  Copyright (c) 2013 Nova Project. All rights reserved.
//

#import "AFHTTPClient.h"


NSString * const kCBClientLoginSuccessNotification;
NSString * const kCBClientLogoutNotification;
NSString * const kCBClientLoginFailureNotification;

@class NPContact;

@interface CBClient : AFHTTPClient

@property (nonatomic, readonly, getter = unreadTransactions) NSUInteger unreadTransactions;
@property (nonatomic, readonly) CGFloat balance;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *walletHash;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, readonly, getter = isLogged) BOOL isLogged;
@property (nonatomic, assign, setter = setCheckInterval:) NSUInteger checkInterval;

+ (CBClient *)sharedClient;

- (void)performLogin;
- (void)performLogout;
- (void)updateNofications;

- (void)sendBitcoins:(CGFloat)amount toContact:(NPContact *)contact completion:(void(^)(BOOL success))completion;
@end
