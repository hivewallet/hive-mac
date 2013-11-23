/*
 This service fetches conversion rates and handles conversion.
 */

@interface HIExchangeRateService : NSObject

@property (nonatomic, copy, readonly) NSArray *availableCurrencies;
@property (nonatomic, copy) NSString *preferredCurrency;

+ (HIExchangeRateService *)sharedService;

- (void)exchangeRateForCurrency:(NSString *)currency
                     completion:(void(^)(NSDecimalNumber *value))completion;

@end
