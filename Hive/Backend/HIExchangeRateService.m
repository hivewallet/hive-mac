#import <AFNetworking/AFHTTPClient.h>
#import <AFNetworking/AFHTTPRequestOperation.h>
#import "BCClient.h"
#import "HIExchangeRateService.h"

static NSString *const HIConversionPreferenceKey = @"ConversionCurrency";
static NSString *const HIAvailableCurrenciesPreferencesKey = @"AvailableCurrencies";
static NSString *const HIDefaultCurrency = @"USD";

static const NSTimeInterval HIExchangeRateAutomaticUpdateInterval = 60.0 * 60.0;
static const NSTimeInterval HIExchangeRateMinimumUpdateInterval = 60.0;


@interface HIExchangeRateService () {
    NSArray *_availableCurrencies;
}

@property (nonatomic, strong) AFHTTPClient *client;
@property (nonatomic, strong) NSMutableSet *observers;
@property (nonatomic, strong) NSMutableDictionary *exchangeRates;
@property (nonatomic, copy) NSDate *lastUpdate;

@end


@implementation HIExchangeRateService

+ (HIExchangeRateService *)sharedService {
    static HIExchangeRateService *sharedService = nil;
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        sharedService = [[self class] new];
    });

    return sharedService;
}

- (instancetype)init {
    self = [super init];

    if (self) {
        self.client = [BCClient sharedClient];
        self.observers = [NSMutableSet new];
        self.exchangeRates = [NSMutableDictionary new];
        self.lastUpdate = [NSDate dateWithTimeIntervalSince1970:0];

        [self registerAppNapNotifications];

        [[NSUserDefaults standardUserDefaults] registerDefaults:@{
          HIAvailableCurrenciesPreferencesKey: @[HIDefaultCurrency]
        }];
    }

    return self;
}

- (void)dealloc {
    [self cancelAutomaticUpdate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - user defaults

- (NSArray *)availableCurrencies {
    if (!_availableCurrencies) {
        _availableCurrencies = [[NSUserDefaults standardUserDefaults]
                                objectForKey:HIAvailableCurrenciesPreferencesKey];

        [self performAutomaticUpdate];
    }

    return _availableCurrencies;
}

- (void)setAvailableCurrencies:(NSArray *)availableCurrencies {
    if (![availableCurrencies isEqualToArray:_availableCurrencies]) {
        for (NSString *currency in availableCurrencies) {
            if (![_availableCurrencies containsObject:currency]) {
                HILogInfo(@"Added currency to exchange rate list: %@", currency);
            }
        }

        for (NSString *currency in _availableCurrencies) {
            if (![availableCurrencies containsObject:currency]) {
                HILogInfo(@"Removed currency from exchange rate list: %@", currency);
            }
        }

        _availableCurrencies = [availableCurrencies copy];

        [[NSUserDefaults standardUserDefaults] setObject:_availableCurrencies
                                                  forKey:HIAvailableCurrenciesPreferencesKey];
    }
}

- (NSString *)preferredCurrency {
    NSString *currency = [[NSUserDefaults standardUserDefaults] stringForKey:HIConversionPreferenceKey];
    return [self.availableCurrencies containsObject:currency] ? currency : HIDefaultCurrency;
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
            HILogWarn(@"Invalid response from exchange rate API: %@", error);
        }

        [self notifyOfExchangeRates];

        [self scheduleAutomaticUpdate];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        HILogWarn(@"Couldn't get response from exchange rate API: %@", error);

        [self notifyOfExchangeRates];
    }];

    [self.client.operationQueue addOperation:exchangeRateOperation];
}

- (BOOL)isExchangeRateUpdateNeeded {
    return [[NSDate date] timeIntervalSinceDate:self.lastUpdate] > HIExchangeRateMinimumUpdateInterval;
}

- (void)updateExchangeRatesFromResponse:(NSDictionary *)response {
    [self updateAvailableCurrenciesFromResponse:response];

    for (NSString *currency in self.availableCurrencies) {
        [self updateExchangeRatesForCurrency:currency fromResponse:response];
    }
}

- (void)updateAvailableCurrenciesFromResponse:(NSDictionary *)response {
    NSMutableArray *receivedCurrencies = [NSMutableArray arrayWithCapacity:response.count];

    for (NSString *key in response.allKeys) {
        if (key.length == 3 && [key.uppercaseString isEqual:key]) {
            [receivedCurrencies addObject:key];
        }
    }

    if (receivedCurrencies.count == 0) {
        // something went seriously wrong, cancel the update
        return;
    }

    if (![receivedCurrencies containsObject:HIDefaultCurrency]) {
        // make sure the default never disappears
        [receivedCurrencies addObject:HIDefaultCurrency];
    }

    self.availableCurrencies = [receivedCurrencies sortedArrayUsingSelector:@selector(compare:)];
}

- (void)updateExchangeRatesForCurrency:(NSString *)currency fromResponse:(NSDictionary *)response {
    if (!response[currency]) {
        HILogWarn(@"No currency info returned for %@", currency);
        return;
    }

    NSString *string = [response[currency][@"last"] description];
    NSDecimalNumber *exchangeRate = [NSDecimalNumber decimalNumberWithString:string
                                                                      locale:@{NSLocaleDecimalSeparator: @"."}];

    if (exchangeRate
        && ![exchangeRate isEqual:[NSDecimalNumber zero]]
        && exchangeRate != [NSDecimalNumber notANumber]) {
        self.exchangeRates[currency] = exchangeRate;
    } else {
        HILogWarn(@"Invalid exchange rate for %@: '%@'", currency, string);
        [self.exchangeRates removeObjectForKey:currency];
    }

}

- (void)notifyOfExchangeRates {
    for (NSString *currency in self.availableCurrencies) {
        [self notifyOfExchangeRate:self.exchangeRates[currency] forCurrency:currency];
    }
}

- (void)notifyOfExchangeRate:(NSDecimalNumber *)exchangeRate forCurrency:(NSString *)currency {
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
