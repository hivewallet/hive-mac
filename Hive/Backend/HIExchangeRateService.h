/*
 This service fetches conversion rates and handles conversion.
 */

@interface HIExchangeRateService : NSObject

+ (HIExchangeRateService *)sharedService;

- (void)exchangeRateForCurrency:(NSString *)currency
                     completion:(void(^)(NSDecimalNumber *value))completion;

@end
