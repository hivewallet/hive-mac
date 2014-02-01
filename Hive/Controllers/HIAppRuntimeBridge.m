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
#import "HIBitcoinFormatService.h"
#import "HICurrencyFormatService.h"
#import "HIExchangeRateService.h"
#import "HIProfile.h"
#import "HISecureAppStorage.h"

// API version
// MINOR version must be incremented when new API features are added
// MAJOR version must be incremented when existing API features are changed incompatibly.
static const NSUInteger API_LEVEL_MAJOR = 0;
static const NSUInteger API_LEVEL_MINOR = 1;

static NSString * const kHIAppRuntimeBridgeErrorDomain = @"HIAppRuntimeBridgeErrorDomain";
static const NSInteger kHIAppRuntimeBridgeParsingError = -1000;

@interface HIAppRuntimeBridge () <HIExchangeRateObserver> {
    NSDateFormatter *_ISODateFormatter;
    NSInteger _BTCInSatoshi;
    NSInteger _mBTCInSatoshi;
    NSInteger _uBTCInSatoshi;
    NSString *_IncomingTransactionType;
    NSString *_OutgoingTransactionType;
    NSUInteger _activeApiLevelMajor;
    NSUInteger _activeApiLevelMinor;
    NSMutableSet *_exchangeRateListeners;
    HIApplication *_application;
    NSDictionary *_applicationManifest;
    HISecureAppStorage *_secureStorage;
    NSString *_preferredCurrency;
    NSString *_preferredBitcoinFormat;
}

@end


@implementation HIAppRuntimeBridge

#pragma mark - version checking

+ (BOOL)isApiLevelInApplicationSupported:(HIApplication *)application {
    NSDictionary *manifest = application.manifest;
    NSUInteger apiLevelMajor = [manifest[@"apiLevelMajor"] unsignedIntegerValue];
    NSUInteger apiLevelMinor = [manifest[@"apiLevelMinor"] unsignedIntegerValue];

    return API_LEVEL_MAJOR == apiLevelMajor && API_LEVEL_MINOR >= apiLevelMinor;
}

#pragma mark - Method & property mapping

+ (NSDictionary *)selectorMap {
    static NSDictionary *selectorMap;

    if (!selectorMap) {
        selectorMap = @{
                        @"log:": @"log",
                        @"error:": @"error",
                        @"warn:": @"warn",
                        @"info:": @"info",
                        @"sendMoneyToAddress:amount:callback:": @"sendMoney",
                        @"transactionWithHash:callback:": @"getTransaction",
                        @"getUserInformationWithCallback:": @"getUserInfo",
                        @"getSystemInfoWithCallback:": @"getSystemInfo",
                        @"makeProxiedRequestToURL:options:": @"makeRequest",
                        @"addExchangeRateListener:": @"addExchangeRateListener",
                        @"removeExchangeRateListener:": @"removeExchangeRateListener",
                        @"updateExchangeRateForCurrency:": @"updateExchangeRate",
                        @"userStringForSatoshi:": @"userStringForSatoshi",
                        @"satoshiFromUserString:": @"satoshiFromUserString",
                        @"userStringForValue:currency:": @"userStringForCurrencyValue",
                        @"valueFromUserString:": @"valueFromUserString",
                        };
    }

    return selectorMap;
}

+ (NSDictionary *)keyMap {
    static NSDictionary *keyMap;

    if (!keyMap) {
        keyMap = @{
                   @"_BTCInSatoshi": @"BTC_IN_SATOSHI",
                   @"_mBTCInSatoshi": @"MBTC_IN_SATOSHI",
                   @"_uBTCInSatoshi": @"UBTC_IN_SATOSHI",
                   @"_IncomingTransactionType": @"TX_TYPE_INCOMING",
                   @"_OutgoingTransactionType": @"TX_TYPE_OUTGOING",
                   @"_secureStorage": @"secureStorage",
                   @"_activeApiLevelMajor": @"apiLevelMajor",
                   @"_activeApiLevelMinor": @"apiLevelMinor",
                   };
    }

    return keyMap;
}


#pragma mark - init & cleanup

- (id)initWithApplication:(HIApplication *)application frame:(WebFrame *)frame {

    NSAssert([[self class] isApiLevelInApplicationSupported:application],
             @"Application should not have been loaded");

    self = [super init];

    if (self) {
        _application = application;
        _applicationManifest = application.manifest;
        self.frame = frame;

        _ISODateFormatter = [[NSDateFormatter alloc] init];
        _ISODateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";

        _BTCInSatoshi = SATOSHI;
        _mBTCInSatoshi = SATOSHI / 1000;
        _uBTCInSatoshi = SATOSHI / 1000 / 1000;

        _IncomingTransactionType = @"incoming";
        _OutgoingTransactionType = @"outgoing";

        _activeApiLevelMajor = API_LEVEL_MAJOR;
        _activeApiLevelMinor = API_LEVEL_MINOR;

        _exchangeRateListeners = [NSMutableSet new];
        _secureStorage = [[HISecureAppStorage alloc] initWithApplication:application frame:self.frame];

        // We currently do not send live updates to apps, so remember this.
        _preferredCurrency = [[HIExchangeRateService sharedService] preferredCurrency];
        _preferredBitcoinFormat = [[HIBitcoinFormatService sharedService] preferredFormat];
    }

    return self;
}

- (void)killCallbacks {
    [self removeAllExchangeRateListeners];
}

#pragma mark - JS API methods

- (void)log:(NSString *)message {
    [self logMessage:message withLevel:HILoggerLevelDebug];
}

- (void)error:(NSString *)message {
    [self logMessage:message withLevel:HILoggerLevelError];
}

- (void)warn:(NSString *)message {
    [self logMessage:message withLevel:HILoggerLevelWarn];
}

- (void)info:(NSString *)message {
    [self logMessage:message withLevel:HILoggerLevelInfo];
}

- (void)logMessage:(NSString *)message withLevel:(enum HILoggerLevel)withLevel {
    HILoggerLog([NSString stringWithFormat:@"App:%@", _application.name].UTF8String, "", 0, withLevel, @"%@", message);
}

- (void)sendMoneyToAddress:(NSString *)hash amount:(NSNumber *)amount callback:(WebScriptObject *)callback {

    ValidateArgument(NSString, hash);
    ValidateOptionalArgument(NSNumber, amount);
    ValidateOptionalArgument(WebScriptObject, callback);

    satoshi_t decimal = 0ll;
    if (!IsNullOrUndefined(amount)) {
        decimal = amount.unsignedLongLongValue;
    }

    [self.controller requestPaymentToHash:hash
                                   amount:decimal
                               completion:^(BOOL success, NSString *transactionId) {
        if (!IsNullOrUndefined(callback)) {
            if (success) {
                JSStringRef idParam = JSStringCreateWithCFString((__bridge CFStringRef) transactionId);

                JSValueRef params[2];
                params[0] = JSValueMakeBoolean(self.context, YES);
                params[1] = JSValueMakeString(self.context, idParam);

                [self callCallbackMethod:callback withArguments:params count:2];

                JSStringRelease(idParam);
            } else {
                JSValueRef result = JSValueMakeBoolean(self.context, NO);

                [self callCallbackMethod:callback withArguments:&result count:1];
            }
        }
    }];
}

- (void)transactionWithHash:(NSString *)hash callback:(WebScriptObject *)callback {

    ValidateArgument(NSString, hash);
    ValidateArgument(WebScriptObject, callback);

    NSDictionary *data = [[BCClient sharedClient] transactionDefinitionWithHash:hash];

    if (!data) {
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

- (void)getUserInformationWithCallback:(WebScriptObject *)callback {

    ValidateArgument(WebScriptObject, callback);

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

- (void)getSystemInfoWithCallback:(WebScriptObject *)callback {

    ValidateArgument(WebScriptObject, callback);

    NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];

    NSArray *preferredLanguages = [NSBundle preferredLocalizationsFromArray:[NSBundle mainBundle].localizations];

    NSDictionary *data = @{
                           @"decimalSeparator": [HIBitcoinFormatService sharedService].decimalSeparator,
                           @"locale": preferredLanguages[0],
                           @"preferredCurrency": _preferredCurrency,
                           @"preferredBitcoinFormat": _preferredBitcoinFormat,
                           @"buildNumber": bundleInfo[@"CFBundleVersion"],
                           @"version": bundleInfo[@"CFBundleShortVersionString"],
                         };

    JSValueRef jsonValue = [self valueObjectFromDictionary:data];

    [self callCallbackMethod:callback withArguments:&jsonValue count:1];
}

- (void)makeProxiedRequestToURL:(NSString *)address options:(WebScriptObject *)options {

    ValidateArgument(NSString, address);
    ValidateOptionalArgument(WebScriptObject, options);

    NSURL *url = [NSURL URLWithString:address];
    NSString *hostname = url.host;
    NSArray *allowedHosts = _applicationManifest[@"accessedHosts"];

    if (![allowedHosts containsObject:hostname]) {
        NSString *message = [NSString stringWithFormat:@"application is not allowed to connect to host %@,"
            @" because it is not whitelisted in \"accessedHosts\"", hostname];
        [WebScriptObject throwException:message];
        HILogWarn(@"%@: %@", _application.name, message);
        return;
    }

    NSString *HTTPMethod = [self webScriptObject:options valueForProperty:@"type"] ?: @"GET";
    NSString *dataType = [self webScriptObject:options valueForProperty:@"dataType"];

    HILogInfo(@"Request to %@ (%@)", url, [HTTPMethod uppercaseString]);

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
        HILogWarn(@"%@: Proxied request to %@ has failed: %@", _application.name, url, error);

        [self handleError:error
             forOperation:operation
            errorCallback:errorCallback
         completeCallback:completeCallback];
    }];

    [operation start];
}


#pragma mark - Exchange rate handling

- (void)addExchangeRateListener:(WebScriptObject *)listener {
    ValidateArgument(WebScriptObject, listener);
    if (_exchangeRateListeners.count == 0) {
        [[HIExchangeRateService sharedService] addExchangeRateObserver:self];
    }
    [_exchangeRateListeners addObject:listener];
}

- (void)removeExchangeRateListener:(WebScriptObject *)listener {
    ValidateArgument(WebScriptObject, listener);
    [_exchangeRateListeners removeObject:listener];
    if (_exchangeRateListeners.count == 0) {
        [[HIExchangeRateService sharedService] removeExchangeRateObserver:self];
    }
}

- (void)removeAllExchangeRateListeners {
    for (WebScriptObject *listener in [_exchangeRateListeners copy]) {
        [self removeExchangeRateListener:listener];
    }
}

- (void)updateExchangeRateForCurrency:(NSString *)currency {
    ValidateArgument(NSString, currency);
    [[HIExchangeRateService sharedService] updateExchangeRateForCurrency:currency];
}

- (void)exchangeRateUpdatedTo:(NSDecimalNumber *)exchangeRate forCurrency:(NSString *)currency {
    JSValueRef params[2];
    params[0] = JSValueMakeString(self.context, JSStringCreateWithCFString((__bridge CFStringRef)currency));
    params[1] = JSValueMakeNumber(self.context, exchangeRate.doubleValue);

    for (WebScriptObject *listener in _exchangeRateListeners) {
        [self callCallbackMethod:listener withArguments:params count:2];
    }
}

#pragma mark - parse & format

- (NSString *)userStringForSatoshi:(NSNumber *)satoshiValue {
    satoshi_t satoshi = [satoshiValue unsignedLongLongValue];
    return [[HIBitcoinFormatService sharedService] stringForBitcoin:satoshi
                                                         withFormat:_preferredBitcoinFormat];
}

- (NSNumber *)satoshiFromUserString:(NSString *)string {
    NSError *error = nil;
    satoshi_t satoshi = [[HIBitcoinFormatService sharedService] parseString:string
                                                                 withFormat:_preferredBitcoinFormat
                                                                      error:&error];
    return error ? nil : @(satoshi);
}

- (NSString *)userStringForValue:(NSNumber *)value
                        currency:(NSString *)currency {
    HICurrencyFormatService *service = [HICurrencyFormatService sharedService];
    return [service formatValue:value
                     inCurrency:IsNullOrUndefined(currency) ? _preferredCurrency : currency];
}

- (NSNumber *)valueFromUserString:(NSString *)string {
    HICurrencyFormatService *service = [HICurrencyFormatService sharedService];
    return [service parseString:string error:NULL];
}

#pragma mark - Proxied request & response handling

- (NSMutableURLRequest *)requestWithURL:(NSURL *)URL
                                 method:(NSString *)method
                                   data:(id)data
                                headers:(NSDictionary *)headers {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setHTTPMethod:method];
    [request setHTTPShouldHandleCookies:NO];

    if (data) {
        NSString *paramString;

        if ([data isKindOfClass:[NSString class]]) {
            paramString = data;
        } else {
            paramString = AFQueryStringFromParametersWithEncoding(data, NSUTF8StringEncoding);
        }

        if ([@[@"GET", @"HEAD", @"DELETE"] containsObject:method]) {
            NSString *address = URL.absoluteString;
            NSString *separator = ([address rangeOfString:@"?"].location == NSNotFound) ? @"?" : @"&";
            NSString *updatedURL = [address stringByAppendingFormat:@"%@%@", separator, paramString];
            [request setURL:[NSURL URLWithString:updatedURL]];
        } else {
            [request setValue:@"application/x-www-form-urlencoded; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:[paramString dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }

    if (headers) {
        for (NSString *key in headers) {
            [request addValue:[headers[key] description] forHTTPHeaderField:key];
        }
    }

    return request;
}

- (JSValueRef)parseResponseFromOperation:(AFHTTPRequestOperation *)operation requestedDataType:(NSString *)dataType {
    NSString *contentType = operation.response.allHeaderFields[@"Content-Type"];

    JSStringRef jsString = JSStringCreateWithCFString((__bridge CFStringRef) (operation.responseString ?: @""));
    JSValueRef jsValue;

    if ([dataType isEqual:@"json"] || ([contentType hasSuffix:@"/json"] && IsNullOrUndefined(dataType))) {
        jsValue = JSValueMakeFromJSONString(self.context, jsString);
    } else {
        jsValue = JSValueMakeString(self.context, jsString);
    }

    JSStringRelease(jsString);

    return jsValue;
}


- (void)handleSuccessForOperation:(AFHTTPRequestOperation *)operation
                requestedDataType:(NSString *)dataType
                  successCallback:(WebScriptObject *)successCallback
                    errorCallback:(WebScriptObject *)errorCallback
                 completeCallback:(WebScriptObject *)completeCallback {
    JSValueRef response = [self parseResponseFromOperation:operation requestedDataType:dataType];

    if (response) {
        JSValueRef arguments[2];
        arguments[0] = response;
        arguments[1] = JSValueMakeNumber(self.context, operation.response.statusCode);

        [self callCallbackMethod:successCallback withArguments:arguments count:2];
        [self callCallbackMethod:completeCallback withArguments:arguments count:2];
    } else {
        NSError *error = [NSError errorWithDomain:kHIAppRuntimeBridgeErrorDomain
                                             code:kHIAppRuntimeBridgeParsingError
                                         userInfo:@{ NSLocalizedDescriptionKey: @"couldn't parse JSON response" }];

        [self handleError:error forOperation:operation errorCallback:errorCallback completeCallback:completeCallback];
    }
}

- (void)handleError:(NSError *)error
       forOperation:(AFHTTPRequestOperation *)operation
      errorCallback:(WebScriptObject *)errorCallback
   completeCallback:(WebScriptObject *)completeCallback {
    NSDictionary *errorData = @{ @"message": error.localizedDescription };

    JSValueRef arguments[3];
    arguments[0] = [self parseResponseFromOperation:operation requestedDataType:@"text"];
    arguments[1] = JSValueMakeNumber(self.context, operation.response.statusCode);
    arguments[2] = [self valueObjectFromDictionary:errorData];

    [self callCallbackMethod:errorCallback withArguments:arguments count:3];
    [self callCallbackMethod:completeCallback withArguments:arguments count:3];
}

@end
