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


@implementation HIAppRuntimeBridge

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
        // Functions get passed in as WebScriptObjects, which give you access to the function as a JSObject
        JSObjectRef ref = [callback JSObject];

        // Through WebView, you can get to the JS globalContext
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
    
    // Through WebView, you can get to the JS globalContext
    JSContextRef ctx = [_frame globalContext];

    NSDictionary *data = [[BCClient sharedClient] transactionDefinitionWithHash:hash];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";

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
                                  @"timestamp": [formatter stringFromDate:data[@"time"]],
                                  @"inputAddresses": [inputs valueForKey:@"address"],
                                  @"outputAddresses": [outputs valueForKey:@"address"]
                                };

    NSString *jsonTransaction = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:transaction options:0 error:NULL] encoding:NSUTF8StringEncoding];
    
    JSStringRef transString = JSStringCreateWithCFString((__bridge CFStringRef)jsonTransaction);
    JSValueRef retValue = JSValueMakeFromJSONString(ctx, transString);
    JSObjectCallAsFunction(ctx, ref, NULL, 1, &retValue, NULL);
    JSStringRelease(transString);
}

- (void)getClientInformationWithCallback:(WebScriptObject *)callback
{
    JSObjectRef ref = [callback JSObject];
    
    // Through WebView, you can get to the JS globalContext
    JSContextRef ctx = [_frame globalContext];

    HIProfile *profile = [[HIProfile alloc] init];

    NSDictionary *data = @{
                           @"firstName": profile.firstname ? profile.lastname : [NSNull null],
                           @"lastName": profile.lastname ? profile.lastname : [NSNull null],
                           @"email": profile.email ? profile.email : [NSNull null],
                           @"address": [[BCClient sharedClient] walletHash]
                         };

    NSString *jsonData = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:data options:0 error:NULL] encoding:NSUTF8StringEncoding];
    
    JSStringRef dataString = JSStringCreateWithCFString((__bridge CFStringRef)jsonData);
    JSValueRef retValue = JSValueMakeFromJSONString(ctx, dataString);
    JSObjectCallAsFunction(ctx, ref, NULL, 1, &retValue, NULL);
    JSStringRelease(dataString);
}

+ (NSString *) webScriptNameForSelector:(SEL)sel
{
    if (sel == @selector(sendCoinsToAddress:amount:callback:))
        return @"sendCoins";
    if (sel == @selector(transactionWithHash:callback:))
        return @"getTransaction";
    if (sel == @selector(getClientInformationWithCallback:))
        return @"getClientInfo";

    return nil;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if (sel == @selector(sendCoinsToAddress:amount:callback:)) return NO;
    else if (sel == @selector(transactionWithHash:callback:)) return NO;
    else if (sel == @selector(getClientInformationWithCallback:)) return NO;

    return YES;
}

@end
