#import "HIBitcoinFormatService.h"

static NSString *const HIFormatPreferenceKey = @"BitcoinFormat";

@implementation HIBitcoinFormatService

+ (HIBitcoinFormatService *)sharedService {
    static HIBitcoinFormatService *sharedService = nil;
    static dispatch_once_t oncePredicate;

    if (!sharedService) {
        dispatch_once(&oncePredicate, ^{
            sharedService = [[self class] new];
        });
    }

    return sharedService;
}

- (NSString *)decimalSeparator {
    return [self createNumberFormatterWithFormat:@"BTC"].decimalSeparator;
}

- (NSArray *)availableFormats {
    static NSArray *availableBitcoinFormats;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        availableBitcoinFormats = @[@"BTC", @"mBTC", @"µBTC", @"satoshi"];
    });
    return availableBitcoinFormats;
}

- (NSString *)preferredFormat {
    NSString *currency = [[NSUserDefaults standardUserDefaults] stringForKey:HIFormatPreferenceKey];
    return [self.availableFormats containsObject:currency] ? currency : @"mBTC";
}

- (void)setPreferredFormat:(NSString *)preferredFormat {
    [[NSUserDefaults standardUserDefaults] setObject:preferredFormat
                                              forKey:HIFormatPreferenceKey];
}

- (NSString *)stringForBitcoin:(satoshi_t)satoshi {
    return [self stringForBitcoin:satoshi withFormat:self.preferredFormat];
}

- (NSString *)stringForBitcoin:(satoshi_t)satoshi withFormat:(NSString *)format {

    // @1e-8 does not work as a multiplier. The values are always zero.
    // So we convert to a fraction.
    NSNumber *x = [NSDecimalNumber decimalNumberWithMantissa:satoshi
                                                    exponent:-8
                                                  isNegative:NO];
    NSNumberFormatter *formatter = [self createNumberFormatterWithFormat:format];
    return [formatter stringFromNumber:x];
}

- (NSNumberFormatter *)createNumberFormatterWithFormat:(id)format {
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.generatesDecimalNumbers = YES;
    formatter.minimum = @0;
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.minimumIntegerDigits = 1;
    if ([format isEqualToString:@"BTC"]) {
        formatter.minimumFractionDigits = 2;
        formatter.maximumFractionDigits = 8;
        formatter.multiplier = @1;
    } else if ([format isEqualToString:@"mBTC"]) {
        formatter.minimumFractionDigits = 0;
        formatter.maximumFractionDigits = 5;
        formatter.multiplier = @1e3;
    } else if ([format isEqualToString:@"µBTC"]) {
        formatter.minimumFractionDigits = 0;
        formatter.maximumFractionDigits = 2;
        formatter.multiplier = @1e6;
    } else if ([format isEqualToString:@"satoshi"]) {
        formatter.minimumFractionDigits = 0;
        formatter.maximumFractionDigits = 0;
        formatter.multiplier = @1e8;
    } else {
        [NSException raise:@"UnknownBitcoinFormatException"
                    format:@"Unknown Bitcoin format %@", format];
    }
    return formatter;
}

- (satoshi_t)parseString:(NSString *)string
              withFormat:(NSString *)format
                   error:(NSError **)error {

    NSNumberFormatter *formatter = [self createNumberFormatterWithFormat:format];
    if (error) {
        *error = nil;
    }
    NSDecimalNumber *number = nil;
    if ([formatter getObjectValue:&number
                        forString:string
                            range:NULL
                            error:error]) {
        return [number decimalNumberByMultiplyingByPowerOf10:8].longLongValue;
    } else {
        return 0ll;
    }
}

@end
