@protocol HIExchangeRateObserver;

/*
 This service fetches conversion rates and handles conversion.
 */

@interface HIExchangeRateService : NSObject

@property (nonatomic, copy, readonly) NSArray *availableCurrencies;
@property (nonatomic, copy) NSString *preferredCurrency;

+ (HIExchangeRateService *)sharedService;

- (void)addExchangeRateObserver:(id<HIExchangeRateObserver>)observer;
- (void)removeExchangeRateObserver:(id<HIExchangeRateObserver>)observer;

- (void)updateExchangeRateForCurrency:(NSString *)currency;

- (NSString *)formatValue:(NSDecimalNumber *)value
               inCurrency:(NSString *)currency;

@end

@protocol HIExchangeRateObserver<NSObject>

- (void)exchangeRateUpdatedTo:(NSDecimalNumber *)exchangeRate
                  forCurrency:(NSString *)currency;

@end
