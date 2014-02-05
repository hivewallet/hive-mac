#import <AFNetworking/AFHTTPClient.h>
#import <AFNetworking/AFHTTPRequestOperation.h>
#import "BCClient.h"
#import "HIExchangeRateService.h"

static NSString *const HIConversionPreferenceKey = @"ConversionCurrency";
static const NSTimeInterval HIExchangeRateAutomaticUpdateInterval = 60.0 * 60.0;
static const NSTimeInterval HIExchangeRateMinimumUpdateInterval = 60.0;

@interface HIExchangeRateService ()

@property (nonatomic, strong) AFHTTPClient *client;
@property (nonatomic, strong) NSMutableSet *observers;
@property (nonatomic, strong, readonly) NSMutableDictionary *exchangeRates;
@property (nonatomic, copy) NSDate *lastUpdate;

@end

@implementation HIExchangeRateService

+ (HIExchangeRateService *)sharedService {
    static HIExchangeRateService *sharedService = nil;
    static dispatch_once_t oncePredicate;

    if (!sharedService) {
        dispatch_once(&oncePredicate, ^{
            sharedService = [[self class] new];
        });
    }

    return sharedService;
}

- (id)init {
    self = [super init];
    if (self) {
        _client = [BCClient sharedClient];
        _observers = [NSMutableSet new];
        _exchangeRates = [NSMutableDictionary new];
        _lastUpdate = [NSDate dateWithTimeIntervalSince1970:0];

        [self registerAppNapNotifications];
    }
    return self;
}

- (void)dealloc {
    [self cancelAutomaticUpdate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - user defaults

- (NSArray *)availableCurrencies {
    static NSArray *availableCurrencies;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        availableCurrencies =
            @[
              @"AUD", @"BRL", @"CAD", @"CHF", @"CNY", @"EUR", @"GBP", @"ILS", @"JPY",
              @"NOK", @"NZD", @"PLN", @"RUB", @"SEK", @"SGD", @"TRY", @"USD", @"ZAR",
            ];
    });
    return availableCurrencies;
}

- (NSString *)preferredCurrency {
    NSString *currency = [[NSUserDefaults standardUserDefaults] stringForKey:HIConversionPreferenceKey];
    return [self.availableCurrencies containsObject:currency] ? currency : @"USD";
}

- (void)setPreferredCurrency:(NSString *)preferredCurrency {
    [[NSUserDefaults standardUserDefaults] setObject:preferredCurrency
                                              forKey:HIConversionPreferenceKey];
}

#pragma mark - exchange rate observation

- (void)addExchangeRateObserver:(id<HIExchangeRateObserver>)observer {
    if (self.observers.count == 0 && [self shouldUpdateAutomatically]) {
        [self scheduleAutomaticUpdate];
    }
    [self.observers addObject:observer];
}

- (void)removeExchangeRateObserver:(id<HIExchangeRateObserver>)observer {
    [self.observers removeObject:observer];
    if (self.observers.count == 0) {
        [self cancelAutomaticUpdate];
    }
}

- (void)updateExchangeRateForCurrency:(NSString *)currency {
    if (![self isExchangeRateUpdateNeeded]) {
        [self notifyOfExchangeRates];
        return;
    }

    // Currency is not used, because we can fetch all rates at once.
    // We keep the parameter, so we don't have to change the API when changing providers.
    NSURL *URL = [NSURL URLWithString:@"https://api.bitcoinaverage.com/ticker/all"];

    AFHTTPRequestOperation *exchangeRateOperation =
        [self.client HTTPRequestOperationWithRequest:[NSURLRequest requestWithURL:URL]
                                             success:^(AFHTTPRequestOperation *operation, id responseData) {

        NSError *error = nil;
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];

        if (response && !error) {
            [self updateExchangeRatesFromResponse:response];
            self.lastUpdate = [NSDate date];
        } else {
            HILogWarn(@"Invalid response from exchange rate API for %@: %@", currency, error);
            [self.exchangeRates removeAllObjects];
        }

        [self notifyOfExchangeRates];

        [self scheduleAutomaticUpdate];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        HILogWarn(@"Couldn't get response from exchange rate API: %@", error);

        [self.exchangeRates removeAllObjects];
        [self notifyOfExchangeRates];
    }];

    [self.client.operationQueue addOperation:exchangeRateOperation];
}

- (BOOL)isExchangeRateUpdateNeeded {
    return [[NSDate date] timeIntervalSinceDate:self.lastUpdate] > HIExchangeRateMinimumUpdateInterval;
}

- (void)updateExchangeRatesFromResponse:(NSDictionary *)response {
    for (NSString *currency in self.availableCurrencies) {
        [self updateExchangeRatesForCurrency:currency fromResponse:response];
    }
}

- (void)updateExchangeRatesForCurrency:(NSString *)currency fromResponse:(NSDictionary *)response {
    if (!response[currency]) {
        HILogWarn(@"No currency info returned for %@", currency);
        return;
    }

    NSString *string = [response[currency][@"last"] description];
    NSDecimalNumber *exchangeRate = [NSDecimalNumber decimalNumberWithString:string
                                                                      locale:@{NSLocaleDecimalSeparator: @"."}];

    if (exchangeRate && exchangeRate != [NSDecimalNumber notANumber]) {
        self.exchangeRates[currency] = exchangeRate;
    } else {
        [self.exchangeRates removeObjectForKey:currency];
    }

}

- (void)notifyOfExchangeRates {
    for (NSString *currency in self.availableCurrencies) {
        [self notifyOfExchangeRate:self.exchangeRates[currency]
                       forCurrency:currency];
    }
}

- (void)notifyOfExchangeRate:(NSDecimalNumber *)exchangeRate
                 forCurrency:(NSString *)currency {
    for (id<HIExchangeRateObserver> observer in self.observers) {
        [observer exchangeRateUpdatedTo:exchangeRate forCurrency:currency];
    }
}

#pragma mark - automatic updates

- (void)performAutomaticUpdate {
    [self updateExchangeRateForCurrency:self.preferredCurrency];
}

- (void)scheduleAutomaticUpdate {
    [self cancelAutomaticUpdate];
    [self performSelector:@selector(performAutomaticUpdate)
               withObject:nil
               afterDelay:HIExchangeRateAutomaticUpdateInterval];
}

- (void)cancelAutomaticUpdate {
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(performAutomaticUpdate)
                                               object:nil];
}

#pragma mark - app nap

- (void)didChangeAppNapState:(NSNotification *)notification {
    BOOL visible = [self shouldUpdateAutomatically];
    if (visible) {
        if (self.observers.count > 0) {
            [self performAutomaticUpdate];
        }
    } else {
        [self cancelAutomaticUpdate];
    }
}

- (BOOL)shouldUpdateAutomatically {
    #pragma deploymate push "ignored-api-availability"
    return ![NSApp respondsToSelector:@selector(occlusionState)]
        || ([NSApp occlusionState] & NSApplicationOcclusionStateVisible);
    #pragma deploymate pop
}

- (void)registerAppNapNotifications {
    #pragma deploymate push "ignored-api-availability"
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangeAppNapState:)
                                                     name:NSApplicationDidChangeOcclusionStateNotification
                                                   object:nil];
    }
    #pragma deploymate pop
}

@end
