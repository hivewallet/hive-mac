#import <AFNetworking/AFHTTPClient.h>
#import <AFNetworking/AFHTTPRequestOperation.h>
#import "BCClient.h"
#import "HIExchangeRateService.h"

static NSString *const HIConversionPreferenceKey = @"ConversionCurrency";
static const NSTimeInterval HIExchangeRateAutomaticUpdateInterval = 60.0 * 60.0;

@interface HIExchangeRateService ()

@property (nonatomic, strong) AFHTTPClient *client;
@property (nonatomic, strong) NSMutableSet *observers;

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
              @"AUD", @"BRL", @"CAD", @"CHF", @"CNY", @"CZK", @"EUR", @"GBP", @"ILS", @"JPY",
              @"NOK", @"NZD", @"PLN", @"RUB", @"SEK", @"SGD", @"USD", @"ZAR",
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
    NSURL *URL =
        [NSURL URLWithString:[NSString stringWithFormat:@"https://api.bitcoinaverage.com/ticker/%@", currency]];

    AFHTTPRequestOperation *exchangeRateOperation =
        [self.client HTTPRequestOperationWithRequest:[NSURLRequest requestWithURL:URL]
                                             success:^(AFHTTPRequestOperation *operation, id responseData) {

        NSError *error = nil;
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];

        NSDecimalNumber *exchangeRate = nil;
        if (response && !error) {
            NSString *string = [response[@"last"] description];
            exchangeRate = [NSDecimalNumber decimalNumberWithString:string
                                                             locale:@{NSLocaleDecimalSeparator: @"."}];

            HILogInfo(@"Got response from exchange rate API for %@: %@", currency, string);

            if (exchangeRate == [NSDecimalNumber notANumber]) {
                exchangeRate = nil;
            }
        } else {
            HILogWarn(@"Invalid response from exchange rate API for %@: %@", currency, error);
        }

        [self notifyOfExchangeRate:exchangeRate forCurrency:currency];

        [self scheduleAutomaticUpdate];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        HILogWarn(@"Couldn't get response from exchange rate API for %@: %@", currency, error);

        [self notifyOfExchangeRate:nil forCurrency:currency];
    }];

    [self.client.operationQueue addOperation:exchangeRateOperation];
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
        HILogDebug(@"Hive became visible");
        if (self.observers.count > 0) {
            [self performAutomaticUpdate];
        }
    } else {
        HILogDebug(@"Hive became invisible");
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
