//
//  HIAppRuntimeBridge.m
//  Hive
//
//  Created by Bazyli Zygan on 27.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>
#import "HIAppRuntimeBridge.h"
#import "BCClient.h"

@implementation HIAppRuntimeBridge

- (void)killCallbacks
{
}

- (void)send:(NSString *)hash amount:(id)amount callback:(WebScriptObject *)callback
{
    NSDecimalNumber *amt = [NSDecimalNumber decimalNumberWithString:[amount description]];

    [self.controller requestPaymentToHash:hash amount:amt completion:^(BOOL success, NSString *hash) {
        // Functions get passed in as WebScriptObjects, which give you access to the function as a JSObject
        JSObjectRef ref = [callback JSObject];
        
        // Through WebView, you can get to the JS globalContext
        JSContextRef ctx = [_frame globalContext];
        
        JSValueRef params[2];
        JSStringRef hashParam = NULL;
        if (hash)
            hashParam = JSStringCreateWithCFString((__bridge CFStringRef)hash);
        params[0] = JSValueMakeBoolean(ctx, success);
        params[1] = JSValueMakeString(ctx, hashParam);
        // And here's where I call the callback and pass in the JS object
        JSObjectCallAsFunction(ctx, ref, NULL, 2, params, NULL);
        if (hash)
            JSStringRelease(hashParam);
        
    }];
}

- (void)send:(NSString *)hash callback:(WebScriptObject*)callback
{
    [self send:hash amount:0 callback:callback];
}

- (void)transactionWithHash:(NSString *)hash callback:(WebScriptObject *)callback
{
    JSObjectRef ref = [callback JSObject];
    
    // Through WebView, you can get to the JS globalContext
    JSContextRef ctx = [_frame globalContext];

    NSDictionary *t = [[BCClient sharedClient] transactionDefinitionWithHash:hash];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy'-'MM'-'dd' 'HH':'mm':'ss' 'z";
    NSDictionary *transaction = @{
                                  @"amount": @((CGFloat) [t[@"amount"] doubleValue] / SATOSHI),
                                  @"txid": t[@"txid"],
                                  @"confirmations": t[@"confirmations"],
                                  @"address": t[@"details"][0][@"address"],
                                  @"category": t[@"details"][0][@"category"],
                                  @"time": [df stringFromDate:t[@"time"]]
                                  };
    NSString *jsonTransaction = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:transaction options:0 error:NULL] encoding:NSUTF8StringEncoding];
    
    JSStringRef transString = JSStringCreateWithCFString((__bridge CFStringRef)jsonTransaction);
    JSValueRef retValue = JSValueMakeFromJSONString(ctx, transString);
    JSObjectCallAsFunction(ctx, ref, NULL, 1, &retValue, NULL);
    JSStringRelease(transString);
}

- (void)clientInformation:(WebScriptObject *)callback
{
    JSObjectRef ref = [callback JSObject];
    
    // Through WebView, you can get to the JS globalContext
    JSContextRef ctx = [_frame globalContext];
    
    NSDictionary *data = @{
                                  @"email": @"test@test.com",
                                  @"firstname": @"John",
                                  @"lastname": @"Doe",
                                  @"address": [BCClient sharedClient].walletHash,
                                  @"street": @"Streetname 1234",
                                  @"zipcode": @"54-242",
                                  @"city": @"Wroclaw",
                                  @"county": @"dolnoslaskie",
                                  @"country": @"Poland"
                                  };
    NSString *jsonData = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:data options:0 error:NULL] encoding:NSUTF8StringEncoding];
    
    JSStringRef dataString = JSStringCreateWithCFString((__bridge CFStringRef)jsonData);
    JSValueRef retValue = JSValueMakeFromJSONString(ctx, dataString);
    JSObjectCallAsFunction(ctx, ref, NULL, 1, &retValue, NULL);
    JSStringRelease(dataString);
}

- (void)sendToAddress:(NSString *)hash amount:(id)amount callback:(WebScriptObject*)callback
{
    NSDecimalNumber *amt = [NSDecimalNumber decimalNumberWithString:[amount description]];

    [self.controller requestPaymentWithAddressToHash:hash amount:amt completion:^(BOOL success, NSString *hash, NSDictionary *address) {
        // Functions get passed in as WebScriptObjects, which give you access to the function as a JSObject
        JSObjectRef ref = [callback JSObject];
        
        // Through WebView, you can get to the JS globalContext
        JSContextRef ctx = [_frame globalContext];
        
        JSValueRef params[3];
        int paramCount = 2;
        JSStringRef hashParam = NULL;
        if (hash)
            hashParam = JSStringCreateWithCFString((__bridge CFStringRef)hash);
        params[0] = JSValueMakeBoolean(ctx, success);
        params[1] = JSValueMakeString(ctx, hashParam);
        
        if (address)
        {
            paramCount = 3;
            NSString *jsonData = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:address options:0 error:NULL] encoding:NSUTF8StringEncoding];
            JSStringRef dataString = JSStringCreateWithCFString((__bridge CFStringRef)jsonData);
            params[2] = JSValueMakeFromJSONString(ctx, dataString);
        }
        // And here's where I call the callback and pass in the JS object
        JSObjectCallAsFunction(ctx, ref, NULL, paramCount, params, NULL);
        if (hash)
            JSStringRelease(hashParam);
        
    }];
}

- (void)sendToAddress:(NSString *)hash callback:(WebScriptObject*)callback
{
    [self sendToAddress:hash amount:0 callback:callback];
}

+ (NSString *) webScriptNameForSelector:(SEL)sel
{
    if (sel == @selector(send:amount:callback:))
        return @"sendCoins";
    if (sel == @selector(send:callback:))
        return @"requestCoins";
    if (sel == @selector(sendToAddress:amount:callback:))
        return @"sendCoinsForAddress";
    if (sel == @selector(sendToAddress:callback:))
        return @"requestCoinsAndAddress";
    if (sel == @selector(transactionWithHash:callback:))
        return @"getTransaction";
    if (sel == @selector(clientInformation:))
        return @"getClientInfo";

    return nil;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if (sel == @selector(send:amount:callback:)) return NO;
    else if (sel == @selector(send:callback:)) return NO;
    else if (sel == @selector(sendToAddress:amount:callback:)) return NO;
    else if (sel == @selector(sendToAddress:callback:)) return NO;
    else if (sel == @selector(transactionWithHash:callback:)) return NO;
    else if (sel == @selector(clientInformation:)) return NO;

    return YES;
}

@end
