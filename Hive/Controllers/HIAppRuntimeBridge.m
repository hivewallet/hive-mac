//
//  HIAppRuntimeBridge.m
//  Hive
//
//  Created by Bazyli Zygan on 27.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import "BCClient.h"
#import "HIApplicationRuntimeViewController.h"
#import "HIAppRuntimeBridge.h"
#import "HICurrencyAmountFormatter.h"
#import "HIExchangeRateService.h"
#import "HIProfile.h"

static NSString * const kHIAppRuntimeBridgeErrorDomain = @"HIAppRuntimeBridgeErrorDomain";
static const NSInteger kHIAppRuntimeBridgeParsingError = -1000;

@interface HIAppRuntimeBridge () <HIExchangeRateObserver>
{
    NSDateFormatter *_ISODateFormatter;
    HICurrencyAmountFormatter *_currencyFormatter;
    NSInteger _BTCInSatoshi;
    NSInteger _mBTCInSatoshi;
    NSInteger _uBTCInSatoshi;
    NSString *_IncomingTransactionType;
    NSString *_OutgoingTransactionType;
    NSMutableSet *_exchangeRateListeners;
    HIApplication *_application;
    NSDictionary *_applicationManifest;
}

@end


@implementation HIAppRuntimeBridge

#pragma mark - Method & property mapping

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
                   };
    }

    return keyMap;
}


#pragma mark - init & cleanup

- (id)initWithApplication:(HIApplication *)application
{
    self = [super init];

    if (self)
    {
        _application = application;
        _applicationManifest = application.manifest;

        _ISODateFormatter = [[NSDateFormatter alloc] init];
        _ISODateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
        _currencyFormatter = [[HICurrencyAmountFormatter alloc] init];

        _BTCInSatoshi = SATOSHI;
        _mBTCInSatoshi = SATOSHI / 1000;
        _uBTCInSatoshi = SATOSHI / 1000 / 1000;

        _IncomingTransactionType = @"incoming";
        _OutgoingTransactionType = @"outgoing";

        _exchangeRateListeners = [NSMutableSet new];
    }

    return self;
}

- (void)killCallbacks
{
    [self removeAllExchangeRateListeners];
}


#pragma mark - JS API methods

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
            if (success)
            {
                JSStringRef idParam = JSStringCreateWithCFString((__bridge CFStringRef) transactionId);

                JSValueRef params[2];
                params[0] = JSValueMakeBoolean(self.context, YES);
                params[1] = JSValueMakeString(self.context, idParam);

                [self callCallbackMethod:callback withArguments:params count:2];

                JSStringRelease(idParam);
            }
            else
            {
                JSValueRef result = JSValueMakeBoolean(self.context, NO);

                [self callCallbackMethod:callback withArguments:&result count:1];
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

    NSDictionary *data = [[BCClient sharedClient] transactionDefinitionWithHash:hash];

    if (!data)
    {
        JSValueRef nullValue = JSValueMakeNull(self.context);

        [self callCallbackMethod:callback withArguments:&nullValue count:1];

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

    [self callCallbackMethod:callback withArguments:&jsonValue count:1];
}

- (void)getUserInformationWithCallback:(WebScriptObject *)callback
{
    if (IsNullOrUndefined(callback))
    {
        [WebScriptObject throwException:@"callback argument is undefined"];
        return;
    }

    HIProfile *profile = [[HIProfile alloc] init];

    NSDictionary *data = @{
                           @"firstName": SafeJSONValue(profile.firstname),
                           @"lastName": SafeJSONValue(profile.lastname),
                           @"email": SafeJSONValue(profile.email),
                           @"address": [[BCClient sharedClient] walletHash]
                         };

    JSValueRef jsonValue = [self valueObjectFromDictionary:data];

    [self callCallbackMethod:callback withArguments:&jsonValue count:1];
}

- (void)getSystemInfoWithCallback:(WebScriptObject *)callback
{
    if (IsNullOrUndefined(callback))
    {
        [WebScriptObject throwException:@"callback argument is undefined"];
        return;
    }

    NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];

    NSArray *languages = [[NSUserDefaults standardUserDefaults] arrayForKey:@"AppleLanguages"];
    NSArray *preferredLanguages =
        (__bridge NSArray *) CFBundleCopyPreferredLocalizationsFromArray((__bridge CFArrayRef) languages);

    NSDictionary *data = @{
                           @"decimalSeparator": _currencyFormatter.decimalSeparator,
                           @"locale": preferredLanguages[0],
                           @"preferredCurrency": [[HIExchangeRateService sharedService] preferredCurrency],
                           @"buildNumber": bundleInfo[@"CFBundleVersion"],
                           @"version": bundleInfo[@"CFBundleShortVersionString"],
                         };

    JSValueRef jsonValue = [self valueObjectFromDictionary:data];

    [self callCallbackMethod:callback withArguments:&jsonValue count:1];
}

- (void)makeProxiedRequestToURL:(NSString *)url options:(WebScriptObject *)options
{
    if (IsNullOrUndefined(url))
    {
        [WebScriptObject throwException:@"url argument is undefined"];
        return;
    }

    NSString *hostname = [[NSURL URLWithString:url] host];
    NSArray *allowedHosts = _applicationManifest[@"accessedHosts"];

    if (![allowedHosts containsObject:hostname])
    {
        NSString *message = [NSString stringWithFormat:@"application is not allowed to connect to host %@", hostname];
        [WebScriptObject throwException:message];
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


#pragma mark - Exchange rate handling

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

- (void)exchangeRateUpdatedTo:(NSDecimalNumber *)exchangeRate forCurrency:(NSString *)currency
{
    JSValueRef params[2];
    params[0] = JSValueMakeString(self.context, JSStringCreateWithCFString((__bridge CFStringRef)currency));
    params[1] = JSValueMakeNumber(self.context,
                                  [exchangeRate decimalNumberByMultiplyingByPowerOf10:8].doubleValue);

    for (WebScriptObject *listener in _exchangeRateListeners)
    {
        [self callCallbackMethod:listener withArguments:params count:2];
    }
}


#pragma mark - Proxied request & response handling

- (NSMutableURLRequest *)requestWithURL:(NSString *)URL
                                 method:(NSString *)method
                                   data:(id)data
                                headers:(NSDictionary *)headers
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URL]];
    [request setHTTPMethod:method];
    [request setHTTPShouldHandleCookies:NO];

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

- (JSValueRef)parseResponseFromOperation:(AFHTTPRequestOperation *)operation requestedDataType:(NSString *)dataType
{
    NSString *contentType = operation.response.allHeaderFields[@"Content-Type"];

    JSStringRef jsString = JSStringCreateWithCFString((__bridge CFStringRef) (operation.responseString ?: @""));
    JSValueRef jsValue;

    if ([dataType isEqual:@"json"] || ([contentType hasSuffix:@"/json"] && IsNullOrUndefined(dataType)))
    {
        jsValue = JSValueMakeFromJSONString(self.context, jsString);
    }
    else
    {
        jsValue = JSValueMakeString(self.context, jsString);
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
    JSValueRef response = [self parseResponseFromOperation:operation requestedDataType:dataType];

    if (response)
    {
        JSValueRef arguments[2];
        arguments[0] = response;
        arguments[1] = JSValueMakeNumber(self.context, operation.response.statusCode);

        [self callCallbackMethod:successCallback withArguments:arguments count:2];
        [self callCallbackMethod:completeCallback withArguments:arguments count:2];
    }
    else
    {
        NSError *error = [NSError errorWithDomain:kHIAppRuntimeBridgeErrorDomain
                                             code:kHIAppRuntimeBridgeParsingError
                                         userInfo:@{ NSLocalizedDescriptionKey: @"couldn't parse JSON response" }];

        [self handleError:error forOperation:operation errorCallback:errorCallback completeCallback:completeCallback];
    }
}

- (void)handleError:(NSError *)error
       forOperation:(AFHTTPRequestOperation *)operation
      errorCallback:(WebScriptObject *)errorCallback
   completeCallback:(WebScriptObject *)completeCallback
{
    NSDictionary *errorData = @{ @"message": error.localizedDescription };

    JSValueRef arguments[3];
    arguments[0] = [self parseResponseFromOperation:operation requestedDataType:@"text"];
    arguments[1] = JSValueMakeNumber(self.context, operation.response.statusCode);
    arguments[2] = [self valueObjectFromDictionary:errorData];

    [self callCallbackMethod:errorCallback withArguments:arguments count:3];
    [self callCallbackMethod:completeCallback withArguments:arguments count:3];
}

@end
