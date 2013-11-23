#import <AFNetworking/AFHTTPClient.h>
#import <AFNetworking/AFHTTPRequestOperation.h>
#import "HIExchangeRateService.h"
#import "BCClient.h"

static NSString *const HIConversionPreferenceKey = @"ConversionCurrency";

@interface HIExchangeRateService ()

@property (nonatomic, strong) AFHTTPClient *client;
@property (nonatomic, strong) AFHTTPRequestOperation *exchangeRateOperation;

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

#pragma mark - networking

- (void)exchangeRateForCurrency:(NSString *)currency
                     completion:(void(^)(NSDecimalNumber *value))completion
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
        NSString *exchange = resp[@"return"][@"sell"][@"value"];
        _exchangeRateOperation = nil;
        completion([NSDecimalNumber decimalNumberWithString:exchange locale:@{NSLocaleDecimalSeparator: @"."}]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        _exchangeRateOperation = nil;
    }];

    [self.client.operationQueue addOperation:_exchangeRateOperation];
}

@end
