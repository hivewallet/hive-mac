#import <AFNetworking/AFHTTPClient.h>
#import <AFNetworking/AFHTTPRequestOperation.h>
#import "BCClient.h"
#import "HIExchangeRateService.h"

static NSString *const HIConversionPreferenceKey = @"ConversionCurrency";

@interface HIExchangeRateService ()

@property (nonatomic, strong) AFHTTPClient *client;
@property (nonatomic, strong) AFHTTPRequestOperation *exchangeRateOperation;
@property (nonatomic, strong) NSMutableSet *observers;

@end

@implementation HIExchangeRateService

+ (HIExchangeRateService *)sharedService
{
    static HIExchangeRateService *sharedService = nil;
    static dispatch_once_t oncePredicate;

    if (!sharedService)
    {
        dispatch_once(&oncePredicate, ^{
            sharedService = [[self class] new];
        });
    }

    return sharedService;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _client = [BCClient sharedClient];
        _observers = [NSMutableSet new];
    }
    return self;
}

#pragma mark - user defaults

- (NSString *)availableCurrencies
{
    // TODO: Add all ISO currency codes.
    return @[@"USD", @"EUR", @"GBP"];
}

- (NSString *)preferredCurrency
{
    NSString *currency = [[NSUserDefaults standardUserDefaults] stringForKey:HIConversionPreferenceKey];
    return [self.availableCurrencies containsObject:currency] ? currency : @"USD";
}

- (void)setPreferredCurrency:(NSString *)preferredCurrency
{
    [[NSUserDefaults standardUserDefaults] setObject:preferredCurrency
                                              forKey:HIConversionPreferenceKey];
}

#pragma mark - exchange rate observation

- (void)addExchangeRateObserver:(id<HIExchangeRateObserver>)observer
{
    [self.observers addObject:observer];
}

- (void)removeExchangeRateObserver:(id<HIExchangeRateObserver>)observer
{
    [self.observers removeObject:observer];
}

- (void)updateExchangeRateForCurrency:(NSString *)currency
{
    if (self.exchangeRateOperation)
    {
        [self.exchangeRateOperation cancel];
        self.exchangeRateOperation = nil;
    }

    NSURL *URL =
        [NSURL URLWithString:[NSString stringWithFormat:@"http://data.mtgox.com/api/1/BTC%@/ticker_fast", currency]];

    self.exchangeRateOperation =
        [self.client HTTPRequestOperationWithRequest:[NSURLRequest requestWithURL:URL]
                                             success:^(AFHTTPRequestOperation *operation, id response) {

        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:response options:0 error:NULL];
        NSString *exchangeRateString = resp[@"return"][@"sell"][@"value"];
        NSDecimalNumber *exchangeRate = [NSDecimalNumber decimalNumberWithString:exchangeRateString
                                                                          locale:@{NSLocaleDecimalSeparator: @"."}];
        [self notifyOfExchangeRate:exchangeRate
                       forCurrency:currency];
        _exchangeRateOperation = nil;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self notifyOfExchangeRate:nil
                       forCurrency:currency];
        _exchangeRateOperation = nil;
    }];

    [self.client.operationQueue addOperation:_exchangeRateOperation];
}

- (void)notifyOfExchangeRate:(NSDecimalNumber *)exchangeRate
                 forCurrency:(NSString *)currency
{
    for (id<HIExchangeRateObserver> observer in self.observers)
    {
        [observer exchangeRateUpdatedTo:exchangeRate forCurrency:currency];
    }
}

#pragma mark - formatting

- (NSString *)formatValue:(NSDecimalNumber *)value inCurrency:(NSString *)currency
{
    // TODO: Some currencies have a different number of decimal digits.
    NSNumberFormatter *currencyNumberFormatter = [NSNumberFormatter new];
    currencyNumberFormatter.localizesFormat = YES;
    currencyNumberFormatter.format = @"#,##0.00";
    return [currencyNumberFormatter stringFromNumber:value];
}


@end
