//
//  HIAppRuntimeBridge.m
//  Hive
//
//  Created by Bazyli Zygan on 27.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>
#import "BCClient.h"
#import "HIAppRuntimeBridge.h"
#import "HIProfile.h"

#define SafeJSONValue(x) ((x) ? (x) : [NSNull null])

@interface HIAppRuntimeBridge ()
{
    NSDateFormatter *_ISODateFormatter;
    NSInteger _BTCInSatoshi;
    NSInteger _mBTCInSatoshi;
    NSInteger _uBTCInSatoshi;
}

@end


@implementation HIAppRuntimeBridge

- (id)init
{
    self = [super init];

    if (self)
    {
        _ISODateFormatter = [[NSDateFormatter alloc] init];
        _ISODateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";

        _BTCInSatoshi = SATOSHI;
        _mBTCInSatoshi = SATOSHI / 1000;
        _uBTCInSatoshi = SATOSHI / 1000 / 1000;
    }

    return self;
}

- (void)killCallbacks
{
}

- (void)sendCoinsToAddress:(NSString *)hash amount:(id)amount callback:(WebScriptObject *)callback
{
    if (amount)
    {
        amount = [NSDecimalNumber decimalNumberWithMantissa:[amount integerValue]
                                                   exponent:-8
                                                 isNegative:NO];
    }

    [self.controller requestPaymentToHash:hash amount:amount completion:^(BOOL success, NSString *hash) {
        JSObjectRef ref = [callback JSObject];
        JSContextRef ctx = [_frame globalContext];

        JSValueRef params[2];
        JSStringRef hashParam = hash ? JSStringCreateWithCFString((__bridge CFStringRef) hash) : NULL;
        params[0] = JSValueMakeBoolean(ctx, success);
        params[1] = JSValueMakeString(ctx, hashParam);

        // And here's where I call the callback and pass in the JS object
        JSObjectCallAsFunction(ctx, ref, NULL, 2, params, NULL);

        if (hashParam)
        {
            JSStringRelease(hashParam);
        }
    }];
}

- (void)transactionWithHash:(NSString *)hash callback:(WebScriptObject *)callback
{
    JSObjectRef ref = [callback JSObject];
    JSContextRef ctx = [_frame globalContext];

    NSDictionary *data = [[BCClient sharedClient] transactionDefinitionWithHash:hash];

    NSInteger amount = [data[@"amount"] integerValue];
    NSInteger absolute = labs(amount);
    BOOL received = (amount >= 0);

    NSArray *inputs = [data[@"details"] filteredArrayUsingPredicate:
                       [NSPredicate predicateWithFormat:@"category = 'received'"]];
    NSArray *outputs = [data[@"details"] filteredArrayUsingPredicate:
                        [NSPredicate predicateWithFormat:@"category = 'sent'"]];

    NSDictionary *transaction = @{
                                  @"id": data[@"txid"],
                                  @"amount": @(absolute),
                                  @"received": @(received),
                                  @"timestamp": [_ISODateFormatter stringFromDate:data[@"time"]],
                                  @"inputAddresses": [inputs valueForKey:@"address"],
                                  @"outputAddresses": [outputs valueForKey:@"address"]
                                };

    JSValueRef jsonValue = [self valueObjectFromDictionary:transaction];
    JSObjectCallAsFunction(ctx, ref, NULL, 1, &jsonValue, NULL);
}

- (void)getClientInformationWithCallback:(WebScriptObject *)callback
{
    JSObjectRef ref = [callback JSObject];
    JSContextRef ctx = [_frame globalContext];

    HIProfile *profile = [[HIProfile alloc] init];

    NSDictionary *data = @{
                           @"firstName": SafeJSONValue(profile.firstname),
                           @"lastName": SafeJSONValue(profile.lastname),
                           @"email": SafeJSONValue(profile.email),
                           @"address": [[BCClient sharedClient] walletHash]
                         };

    JSValueRef jsonValue = [self valueObjectFromDictionary:data];
    JSObjectCallAsFunction(ctx, ref, NULL, 1, &jsonValue, NULL);
}

- (JSValueRef)valueObjectFromDictionary:(NSDictionary *)dictionary
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:NULL];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    JSStringRef jsString = JSStringCreateWithCFString((__bridge CFStringRef) jsonString);
    JSValueRef jsValue = JSValueMakeFromJSONString(self.frame.globalContext, jsString);
    JSStringRelease(jsString);

    return jsValue;
}

+ (NSDictionary *)selectorMap
{
    static NSDictionary *selectorMap;

    if (!selectorMap)
    {
        selectorMap = @{
                        @"sendCoinsToAddress:amount:callback:": @"sendCoins",
                        @"transactionWithHash:callback:": @"getTransaction",
                        @"getClientInformationWithCallback:": @"getClientInfo"
                      };
    }

    return selectorMap;
}

+ (NSDictionary *)keyMap
{
    static NSDictionary *keyMap;

    if (!keyMap)
    {
        keyMap = @{
                   @"_BTCInSatoshi": @"BTC_IN_SATOSHI",
                   @"_mBTCInSatoshi": @"MBTC_IN_SATOSHI",
                   @"_uBTCInSatoshi": @"UBTC_IN_SATOSHI"
                 };
    }

    return keyMap;
}

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
    return [self selectorMap][NSStringFromSelector(sel)];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    return ([self selectorMap][NSStringFromSelector(sel)] == nil);
}

+ (NSString *)webScriptNameForKey:(const char *)name
{
    NSString *key = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
    return [self keyMap][key];
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name
{
    NSString *key = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
    return ([self keyMap][key] == nil);
}

@end
