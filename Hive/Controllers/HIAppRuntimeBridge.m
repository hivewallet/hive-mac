//
//  HIAppRuntimeBridge.m
//  Hive
//
//  Created by Bazyli Zygan on 27.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "BCClient.h"
#import "HIAppRuntimeBridge.h"
#import "HICurrencyAmountFormatter.h"
#import "HIExchangeRateService.h"
#import "HIProfile.h"

#define SafeJSONValue(x) ((x) ?: [NSNull null])
#define IsNullOrUndefined(x) (!(x) || [(x) isKindOfClass:[WebUndefined class]])

static NSString * const kHIAppRuntimeBridgeErrorDomain = @"HIAppRuntimeBridgeErrorDomain";
static const NSInteger kHIAppRuntimeBridgeParsingError = -1000;

@interface HIAppRuntimeBridge ()<HIExchangeRateObserver>
{
    NSDateFormatter *_ISODateFormatter;
    HICurrencyAmountFormatter *_currencyFormatter;
    NSInteger _BTCInSatoshi;
    NSInteger _mBTCInSatoshi;
    NSInteger _uBTCInSatoshi;
    NSString *_IncomingTransactionType;
    NSString *_OutgoingTransactionType;
    NSString *_hiveVersionNumber;
    NSString *_hiveBuildNumber;
    NSString *_locale;
    NSString *_preferredCurrency;
    NSMutableSet *_exchangeRateListeners;
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
        _currencyFormatter = [[HICurrencyAmountFormatter alloc] init];

        _BTCInSatoshi = SATOSHI;
        _mBTCInSatoshi = SATOSHI / 1000;
        _uBTCInSatoshi = SATOSHI / 1000 / 1000;

        _IncomingTransactionType = @"incoming";
        _OutgoingTransactionType = @"outgoing";

        _hiveBuildNumber = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
        _hiveVersionNumber = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];

        NSArray *languages = [[NSUserDefaults standardUserDefaults] arrayForKey:@"AppleLanguages"];
        NSArray *preferredLanguages =
            (__bridge NSArray *)CFBundleCopyPreferredLocalizationsFromArray((__bridge CFArrayRef)languages);
        _locale = preferredLanguages[0];

        HIExchangeRateService *exchangeRateService = [HIExchangeRateService sharedService];
        _preferredCurrency = exchangeRateService.preferredCurrency;
        _exchangeRateListeners = [NSMutableSet new];
    }

    return self;
}

- (void)killCallbacks
{
    [self removeAllExchangeRateListeners];
}

- (void)sendMoneyToAddress:(NSString *)hash amount:(NSNumber *)amount callback:(WebScriptObject *)callback
{
    if (IsNullOrUndefined(hash))
    {
        [WebScriptObject throwException:@"hash argument is undefined"];
        return;
    }

    NSDecimalNumber *decimal = nil;

    if (!IsNullOrUndefined(amount))
    {
        decimal = [NSDecimalNumber decimalNumberWithMantissa:[amount integerValue]
                                                    exponent:-8
                                                  isNegative:NO];
    }

    [self.controller requestPaymentToHash:hash
                                   amount:decimal
                               completion:^(BOOL success, NSString *transactionId) {
        if (!IsNullOrUndefined(callback))
        {
            JSObjectRef ref = [callback JSObject];

            if (!ref)
            {
                // app was already closed
                return;
            }

            JSContextRef ctx = self.frame.globalContext;

            if (success)
            {
                JSStringRef idParam = JSStringCreateWithCFString((__bridge CFStringRef) transactionId);

                JSValueRef params[2];
                params[0] = JSValueMakeBoolean(ctx, YES);
                params[1] = JSValueMakeString(ctx, idParam);

                JSObjectCallAsFunction(ctx, ref, NULL, 2, params, NULL);
                JSStringRelease(idParam);
            }
            else
            {
                JSValueRef result = JSValueMakeBoolean(ctx, NO);
                JSObjectCallAsFunction(ctx, ref, NULL, 1, &result, NULL);
            }
        }
    }];
}

- (void)transactionWithHash:(NSString *)hash callback:(WebScriptObject *)callback
{
    if (IsNullOrUndefined(callback))
    {
        [WebScriptObject throwException:@"callback argument is undefined"];
        return;
    }

    JSObjectRef ref = [callback JSObject];
    JSContextRef ctx = self.frame.globalContext;

    NSDictionary *data = [[BCClient sharedClient] transactionDefinitionWithHash:hash];

    if (!data)
    {
        JSValueRef nullValue = JSValueMakeNull(ctx);
        JSObjectCallAsFunction(ctx, ref, NULL, 1, &nullValue, NULL);
        return;
    }

    NSInteger amount = [data[@"amount"] integerValue];
    NSInteger absolute = labs(amount);
    BOOL incoming = (amount >= 0);

    NSArray *inputs = [data[@"details"] filteredArrayUsingPredicate:
                       [NSPredicate predicateWithFormat:@"category = 'received'"]];
    NSArray *outputs = [data[@"details"] filteredArrayUsingPredicate:
                        [NSPredicate predicateWithFormat:@"category = 'sent'"]];

    NSDictionary *transaction = @{
                                  @"id": data[@"txid"],
                                  @"type": (incoming ? _IncomingTransactionType : _OutgoingTransactionType),
                                  @"amount": @(absolute),
                                  @"timestamp": [_ISODateFormatter stringFromDate:data[@"time"]],
                                  @"inputAddresses": [inputs valueForKey:@"address"],
                                  @"outputAddresses": [outputs valueForKey:@"address"]
                                };

    JSValueRef jsonValue = [self valueObjectFromDictionary:transaction];
    JSObjectCallAsFunction(ctx, ref, NULL, 1, &jsonValue, NULL);
}

- (void)getUserInformationWithCallback:(WebScriptObject *)callback
{
    if (IsNullOrUndefined(callback))
    {
        [WebScriptObject throwException:@"callback argument is undefined"];
        return;
    }

    JSObjectRef ref = [callback JSObject];
    JSContextRef ctx = self.frame.globalContext;

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

- (void)getSystemInfoWithCallback:(WebScriptObject *)callback
{
    if (IsNullOrUndefined(callback))
    {
        [WebScriptObject throwException:@"callback argument is undefined"];
        return;
    }

    JSObjectRef ref = [callback JSObject];
    JSContextRef ctx = self.frame.globalContext;

    NSDictionary *data = @{
                           @"decimalSeparator": _currencyFormatter.decimalSeparator
                         };

    JSValueRef jsonValue = [self valueObjectFromDictionary:data];
    JSObjectCallAsFunction(ctx, ref, NULL, 1, &jsonValue, NULL);
}

- (void)makeProxiedRequestToURL:(NSString *)url options:(WebScriptObject *)options
{
    if (IsNullOrUndefined(url))
    {
        [WebScriptObject throwException:@"url argument is undefined"];
        return;
    }

    NSString *HTTPMethod = [self webScriptObject:options valueForProperty:@"type"] ?: @"GET";
    NSString *dataType = [self webScriptObject:options valueForProperty:@"dataType"];

    WebScriptObject *successCallback = [self webScriptObject:options valueForProperty:@"success"];
    WebScriptObject *errorCallback = [self webScriptObject:options valueForProperty:@"error"];
    WebScriptObject *completeCallback = [self webScriptObject:options valueForProperty:@"complete"];

    WebScriptObject *headers = [self webScriptObject:options valueForProperty:@"headers"];
    NSDictionary *headerHash = [self dictionaryFromWebScriptObject:headers];

    WebScriptObject *data = [self webScriptObject:options valueForProperty:@"data"];
    id processedData = [data isKindOfClass:[NSString class]] ? data : [self dictionaryFromWebScriptObject:data];

    NSMutableURLRequest *request = [self requestWithURL:url
                                                 method:HTTPMethod
                                                   data:processedData
                                                headers:headerHash];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self handleSuccessForOperation:operation
                      requestedDataType:dataType
                        successCallback:successCallback
                          errorCallback:errorCallback
                       completeCallback:completeCallback];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self handleError:error
             forOperation:operation
            errorCallback:errorCallback
         completeCallback:completeCallback];
    }];

    [operation start];
}

- (NSMutableURLRequest *)requestWithURL:(NSString *)URL
                                 method:(NSString *)method
                                   data:(id)data
                                headers:(NSDictionary *)headers
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]];
    [request setHTTPMethod:method];

    if (data)
    {
        NSString *paramString;

        if ([data isKindOfClass:[NSString class]])
        {
            paramString = data;
        }
        else
        {
            paramString = AFQueryStringFromParametersWithEncoding(data, NSUTF8StringEncoding);
        }

        if ([@[@"GET", @"HEAD", @"DELETE"] containsObject:method])
        {
            NSString *separator = ([URL rangeOfString:@"?"].location == NSNotFound) ? @"?" : @"&";
            NSString *updatedURL = [URL stringByAppendingFormat:@"%@%@", separator, paramString];
            [request setURL:[NSURL URLWithString:updatedURL]];
        }
        else
        {
            [request setValue:@"application/x-www-form-urlencoded; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:[paramString dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }

    if (headers)
    {
        for (NSString *key in headers)
        {
            [request addValue:[headers[key] description] forHTTPHeaderField:key];
        }
    }

    return request;
}

- (void)addExchangeRateListener:(WebScriptObject *)listener
{
    if (IsNullOrUndefined(listener))
    {
        [WebScriptObject throwException:@"listener is undefined"];
        return;
    }
    if (_exchangeRateListeners.count == 0)
    {
        [[HIExchangeRateService sharedService] addExchangeRateObserver:self];
    }
    [_exchangeRateListeners addObject:listener];
}

- (void)removeExchangeRateListener:(WebScriptObject *)listener
{
    [_exchangeRateListeners removeObject:listener];
    if (_exchangeRateListeners.count == 0)
    {
        [[HIExchangeRateService sharedService] removeExchangeRateObserver:self];
    }
}

- (void)removeAllExchangeRateListeners
{
    for (WebScriptObject *listener in [_exchangeRateListeners copy])
    {
        [self removeExchangeRateListener:listener];
    }
}

- (void)updateExchangeRateForCurrency:(NSString *)currency
{
    [[HIExchangeRateService sharedService] updateExchangeRateForCurrency:currency];
}

- (JSValueRef)parseResponseFromOperation:(AFHTTPRequestOperation *)operation requestedDataType:(NSString *)dataType
{
    NSString *contentType = operation.response.allHeaderFields[@"Content-Type"];

    JSStringRef jsString = JSStringCreateWithCFString((__bridge CFStringRef) (operation.responseString ?: @""));
    JSValueRef jsValue;

    if ([dataType isEqual:@"json"] || ([contentType hasSuffix:@"/json"] && IsNullOrUndefined(dataType)))
    {
        jsValue = JSValueMakeFromJSONString(self.frame.globalContext, jsString);
    }
    else
    {
        jsValue = JSValueMakeString(self.frame.globalContext, jsString);
    }

    JSStringRelease(jsString);

    return jsValue;
}


- (void)handleSuccessForOperation:(AFHTTPRequestOperation *)operation
                requestedDataType:(NSString *)dataType
                  successCallback:(WebScriptObject *)successCallback
                    errorCallback:(WebScriptObject *)errorCallback
                 completeCallback:(WebScriptObject *)completeCallback
{
    JSGlobalContextRef context = self.frame.globalContext;
    JSValueRef response = [self parseResponseFromOperation:operation requestedDataType:dataType];

    if (response)
    {
        JSValueRef arguments[2];
        arguments[0] = response;
        arguments[1] = JSValueMakeNumber(context, operation.response.statusCode);

        if (successCallback)
        {
            JSObjectCallAsFunction(context, [successCallback JSObject], NULL, 2, arguments, NULL);
        }

        if (completeCallback)
        {
            JSObjectCallAsFunction(context, [completeCallback JSObject], NULL, 2, arguments, NULL);
        }
    }
    else
    {
        NSString *message = [NSString stringWithFormat:@"couldn't parse response: '%@'", operation.responseString];
        NSError *error = [NSError errorWithDomain:kHIAppRuntimeBridgeErrorDomain
                                             code:kHIAppRuntimeBridgeParsingError
                                         userInfo:@{ NSLocalizedDescriptionKey: message }];

        [self handleError:error forOperation:operation errorCallback:errorCallback completeCallback:completeCallback];
    }
}

- (void)handleError:(NSError *)error
       forOperation:(AFHTTPRequestOperation *)operation
      errorCallback:(WebScriptObject *)errorCallback
   completeCallback:(WebScriptObject *)completeCallback
{
    JSGlobalContextRef context = self.frame.globalContext;
    NSDictionary *errorData = @{ @"message": error.localizedDescription };

    JSValueRef arguments[3];
    arguments[0] = [self parseResponseFromOperation:operation requestedDataType:@"text"];
    arguments[1] = JSValueMakeNumber(context, operation.response.statusCode);
    arguments[2] = [self valueObjectFromDictionary:errorData];

    if (errorCallback)
    {
        JSObjectCallAsFunction(context, [errorCallback JSObject], NULL, 3, arguments, NULL);
    }

    if (completeCallback)
    {
        JSObjectCallAsFunction(context, [completeCallback JSObject], NULL, 3, arguments, NULL);
    }
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

- (NSDictionary *)dictionaryFromWebScriptObject:(WebScriptObject *)object
{
    if (IsNullOrUndefined(object))
    {
        return nil;
    }

    JSPropertyNameArrayRef properties = JSObjectCopyPropertyNames(self.frame.globalContext, [object JSObject]);
    size_t count = JSPropertyNameArrayGetCount(properties);

    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:count];

    for (NSInteger i = 0; i < count; i++)
    {
        JSStringRef property = JSPropertyNameArrayGetNameAtIndex(properties, i);
        NSString *propertyName = CFBridgingRelease(JSStringCopyCFString(kCFAllocatorDefault, property));

        id value = [object valueForKey:propertyName];

        if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]])
        {
            dictionary[propertyName] = value;
        }
        else
        {
            NSLog(@"dictionaryFromWebScriptObject: ignoring value for property %@: %@", propertyName, value);
        }
    }

    JSPropertyNameArrayRelease(properties);

    return dictionary;
}

- (id)webScriptObject:(WebScriptObject *)object valueForProperty:(NSString *)property
{
    if ([self webScriptObject:object hasProperty:property])
    {
        return [object valueForKey:property];
    }
    else
    {
        return nil;
    }
}

- (BOOL)webScriptObject:(WebScriptObject *)object hasProperty:(NSString *)property
{
    if (IsNullOrUndefined(object))
    {
        return NO;
    }

    JSStringRef jsString = JSStringCreateWithCFString((__bridge CFStringRef) property);
    BOOL hasProperty = JSObjectHasProperty(self.frame.globalContext, [object JSObject], jsString);
    JSStringRelease(jsString);

    return hasProperty;
}

+ (NSDictionary *)selectorMap
{
    static NSDictionary *selectorMap;

    if (!selectorMap)
    {
        selectorMap = @{
                        @"sendMoneyToAddress:amount:callback:": @"sendMoney",
                        @"transactionWithHash:callback:": @"getTransaction",
                        @"getUserInformationWithCallback:": @"getUserInfo",
                        @"getSystemInfoWithCallback:": @"getSystemInfo",
                        @"makeProxiedRequestToURL:options:": @"makeRequest",
                        @"addExchangeRateListener:": @"addExchangeRateListener",
                        @"removeExchangeRateListener:": @"removeExchangeRateListener",
                        @"updateExchangeRateForCurrency:": @"updateExchangeRate",
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
                   @"_uBTCInSatoshi": @"UBTC_IN_SATOSHI",
                   @"_IncomingTransactionType": @"TX_TYPE_INCOMING",
                   @"_OutgoingTransactionType": @"TX_TYPE_OUTGOING",
                   @"_hiveBuildNumber": @"BUILD_NUMBER",
                   @"_hiveVersionNumber": @"VERSION",
                   @"_locale": @"LOCALE",
                   @"_preferredCurrency": @"PREFERRED_CURRENCY",
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

#pragma mark - HIExchangeRateObserver

- (void)exchangeRateUpdatedTo:(NSDecimalNumber *)exchangeRate forCurrency:(NSString *)currency
{
    JSContextRef ctx = self.frame.globalContext;
    JSValueRef params[2];
    params[0] = JSValueMakeString(ctx, JSStringCreateWithCFString((__bridge CFStringRef)currency));
    params[1] = JSValueMakeNumber(ctx, [exchangeRate decimalNumberByMultiplyingByPowerOf10:8].doubleValue);

    for (WebScriptObject *listener in _exchangeRateListeners)
    {
        JSObjectRef ref = listener.JSObject;
        JSObjectCallAsFunction(ctx, ref, NULL, 2, params, NULL);
    }

}

@end
