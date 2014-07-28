#import "HIBitcoinFormatService.h"

#import "NSDecimalNumber+HISatoshiConversion.h"
#import "NSString+HICleanUpNumber.h"

NSString *const HIPreferredFormatChangeNotification = @"HIPreferredFormatChangeNotification";

static NSString *const HIFormatPreferenceKey = @"BitcoinFormat";
static NSString *const DefaultBitcoinFormat = @"mBTC";

@implementation HIBitcoinFormatService

+ (HIBitcoinFormatService *)sharedService {
    static HIBitcoinFormatService *sharedService = nil;
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        sharedService = [[self class] new];
    });

    return sharedService;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.locale = [NSLocale autoupdatingCurrentLocale];
    }
    return self;
}

- (NSString *)decimalSeparator {
    return [self createNumberFormatterWithFormat:@"BTC"].decimalSeparator;
}

- (NSArray *)availableFormats {
    static NSArray *availableBitcoinFormats;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        availableBitcoinFormats = @[@"BTC", @"mBTC", @"bits"];
    });
    return availableBitcoinFormats;
}

- (NSString *)preferredFormat {
    NSString *currency = [[NSUserDefaults standardUserDefaults] stringForKey:HIFormatPreferenceKey];
    return [self.availableFormats containsObject:currency] ? currency : DefaultBitcoinFormat;
}

- (void)setPreferredFormat:(NSString *)preferredFormat {
    NSString *oldValue = self.preferredFormat;
    if (![oldValue isEqualToString:preferredFormat]) {
        [[NSUserDefaults standardUserDefaults] setObject:preferredFormat
                                                  forKey:HIFormatPreferenceKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:HIPreferredFormatChangeNotification
                                                            object:self
                                                          userInfo:nil];
    }
}

- (NSString *)stringWithUnitForBitcoin:(satoshi_t)satoshi {
    return [NSString stringWithFormat:@"%@ %@", [self stringForBitcoin:satoshi], self.preferredFormat];
}

- (NSString *)stringForBitcoin:(satoshi_t)satoshi {
    return [self stringForBitcoin:satoshi withFormat:self.preferredFormat];
}

- (NSString *)stringForBitcoin:(satoshi_t)satoshi withFormat:(NSString *)format {
    NSNumberFormatter *formatter = [self createNumberFormatterWithFormat:format];

    NSDecimalNumber *number = [NSDecimalNumber hiDecimalNumberWithSatoshi:satoshi];
    number = [number decimalNumberByMultiplyingByPowerOf10:[self shiftForFormat:format]];

    return [formatter stringFromNumber:number];
}

- (NSNumberFormatter *)createNumberFormatterWithFormat:(NSString *)format {
    // Do not use the formatter's multiplier! It causes rounding errors!
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.locale = self.locale;
    formatter.generatesDecimalNumbers = YES;
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.minimumIntegerDigits = 1;
    if ([format isEqualToString:@"BTC"]) {
        formatter.minimumFractionDigits = 2;
        formatter.maximumFractionDigits = 8;
    } else if ([format isEqualToString:@"mBTC"]) {
        formatter.minimumFractionDigits = 0;
        formatter.maximumFractionDigits = 5;
    } else if ([format isEqualToString:@"bits"]) {
        formatter.minimumFractionDigits = 0;
        formatter.maximumFractionDigits = 2;
    } else {
        @throw [self createUnknownFormatException:format];
    }
    return formatter;
}

- (NSException *)createUnknownFormatException:(NSString *)format {
    return [NSException exceptionWithName:@"UnknownBitcoinFormatException"
                                       reason:[NSString stringWithFormat:@"Unknown Bitcoin format %@", format]
                                     userInfo:nil];
}

- (int)shiftForFormat:(NSString *)format {
    if ([format isEqualToString:@"BTC"]) {
        return 0;
    } else if ([format isEqualToString:@"mBTC"]) {
        return 3;
    } else if ([format isEqualToString:@"bits"]) {
        return 6;
    } else {
        @throw [self createUnknownFormatException:format];
    }
}

- (satoshi_t)parseString:(NSString *)string
              withFormat:(NSString *)format
                   error:(NSError **)error {
    return [self parseString:string withFormat:format locale:self.locale error:error];
}

- (satoshi_t)parseString:(NSString *)string
              withFormat:(NSString *)format
                  locale:(NSLocale *)locale
                   error:(NSError **)error {

    NSParameterAssert(string);

    string = [string hi_stringWithCleanedUpDecimalNumberUsingLocale:self.locale] ?: string;

    NSNumberFormatter *formatter = [self createNumberFormatterWithFormat:format];
    formatter.locale = locale;

    if (error) {
        *error = nil;
    }

    NSDecimalNumber *number = nil;

    if ([formatter getObjectValue:&number
                        forString:string
                            range:NULL
                            error:error]) {

        // The value returned by the number formatter is actually wrong, because it rounds to double
        // internally.
        // We just use it for returning an error if the number cannot be parsed.

        number = [[NSDecimalNumber alloc] initWithString:string locale:self.locale];
        number = [number decimalNumberByMultiplyingByPowerOf10:-[self shiftForFormat:format]];
        return number.hiSatoshi;
    } else {
        return 0ll;
    }
}

@end
