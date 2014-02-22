#import "HICurrencyFormatService.h"

@implementation HICurrencyFormatService

+ (HICurrencyFormatService *)sharedService {
    static HICurrencyFormatService *sharedService = nil;
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        sharedService = [[self class] new];
    });

    return sharedService;
}

- (id)init {
    self = [super init];
    if (self) {
        _locale = [NSLocale currentLocale];
    }

    return self;
}

- (NSDictionary *)currencySymbols {
    static NSDictionary *currencySymbols;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        currencySymbols = @{
            @"ALL": @"Lek", @"AFN": @"؋", @"ARS": @"$", @"AWG": @"ƒ",@"AUD": @"$", @"AZN": @"ман", @"BSD": @"$",
            @"BBD": @"$", @"BYR": @"p.", @"BZD": @"BZ$", @"BMD": @"$", @"BOB": @"$b", @"BAM": @"KM", @"BWP": @"P",
            @"BGN": @"лв", @"BRL": @"R$", @"BND": @"$", @"KHR": @"៛", @"CAD": @"$", @"KYD": @"$", @"CLP": @"$",
            @"CNY": @"¥", @"COP": @"$", @"CRC": @"₡", @"HRK": @"kn", @"CUP": @"₱", @"CZK": @"Kč", @"DKK": @"kr",
            @"DOP": @"RD$", @"XCD": @"$", @"EGP": @"£", @"SVC": @"$", @"EEK": @"kr", @"EUR": @"€", @"FKP": @"£",
            @"FJD": @"$", @"GHC": @"¢", @"GIP": @"£", @"GTQ": @"Q", @"GGP": @"£", @"GYD": @"$", @"HNL": @"L",
            @"HKD": @"$", @"HUF": @"Ft", @"ISK": @"kr", @"INR": @"", @"IDR": @"Rp", @"IRR": @"﷼", @"IMP": @"£",
            @"ILS": @"₪", @"JMD": @"J$", @"JPY": @"¥", @"JEP": @"£", @"KZT": @"лв", @"KPW": @"₩", @"KRW": @"₩",
            @"KGS": @"лв", @"LAK": @"₭", @"LVL": @"Ls", @"LBP": @"£", @"LRD": @"$", @"LTL": @"Lt", @"MKD": @"ден",
            @"MYR": @"RM", @"MUR": @"₨", @"MXN": @"$", @"MNT": @"₮", @"MZN": @"MT", @"NAD": @"$", @"NPR": @"₨",
            @"ANG": @"ƒ", @"NZD": @"$", @"NIO": @"C$", @"NGN": @"₦", @"KPW": @"₩", @"NOK": @"kr", @"OMR": @"﷼",
            @"PKR": @"₨", @"PAB": @"B/.", @"PYG": @"Gs", @"PEN": @"S/.", @"PHP": @"₱", @"PLN": @"zł", @"QAR": @"﷼",
            @"RON": @"lei", @"RUB": @"руб", @"SHP": @"£", @"SAR": @"﷼", @"RSD": @"Дин.", @"SCR": @"₨", @"SGD": @"$",
            @"SBD": @"$", @"SOS": @"S", @"ZAR": @"R", @"KRW": @"₩", @"LKR": @"₨", @"SEK": @"kr", @"CHF": @"CHF",
            @"SRD": @"$", @"SYP": @"£", @"TWD": @"NT$", @"THB": @"฿", @"TTD": @"TT$", @"TRY": @"₺", @"TRL": @"₤",
            @"TVD": @"$", @"UAH": @"₴", @"GBP": @"£", @"USD": @"$", @"UYU": @"$U", @"UZS": @"лв", @"VEF": @"Bs",
            @"VND": @"₫", @"YER": @"﷼", @"ZWD": @"Z$",
        };
    });
    return currencySymbols;
}

- (NSDictionary *)currencyDigits {
    // the number of fraction digits for each currency
    static NSDictionary *currencyDigits;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        currencyDigits = @{
            @"AED": @2, @"AFN": @2, @"ALL": @2, @"AMD": @2, @"ANG": @2, @"AOA": @2, @"ARS": @2, @"AUD": @2,
            @"AWG": @2, @"AZN": @2, @"BAM": @2, @"BBD": @2, @"BDT": @2, @"BGN": @2, @"BHD": @3, @"BIF": @0,
            @"BMD": @2, @"BND": @2, @"BOB": @2, @"BOV": @2, @"BRL": @2, @"BSD": @2, @"BTN": @2, @"BWP": @2,
            @"BYR": @0, @"BZD": @2, @"CAD": @2, @"CDF": @2, @"CHE": @2, @"CHF": @2, @"CHW": @2, @"CLF": @0,
            @"CLP": @0, @"CNY": @2, @"COP": @2, @"COU": @2, @"CRC": @2, @"CUC": @2, @"CUP": @2, @"CVE": @0,
            @"CZK": @2, @"DJF": @0, @"DKK": @2, @"DOP": @2, @"DZD": @2, @"EGP": @2, @"ERN": @2, @"ETB": @2,
            @"EUR": @2, @"FJD": @2, @"FKP": @2, @"GBP": @2, @"GEL": @2, @"GHS": @2, @"GIP": @2, @"GMD": @2,
            @"GNF": @0, @"GTQ": @2, @"GYD": @2, @"HKD": @2, @"HNL": @2, @"HRK": @2, @"HTG": @2, @"HUF": @2,
            @"IDR": @0, @"ILS": @2, @"INR": @2, @"IQD": @3, @"IRR": @0, @"ISK": @0, @"JMD": @2, @"JOD": @3,
            @"JPY": @0, @"KES": @2, @"KGS": @2, @"KHR": @2, @"KMF": @0, @"KPW": @0, @"KRW": @0, @"KWD": @3,
            @"KYD": @2, @"KZT": @2, @"LAK": @0, @"LBP": @0, @"LKR": @2, @"LRD": @2, @"LSL": @2, @"LTL": @2,
            @"LVL": @2, @"LYD": @3, @"MAD": @2, @"MDL": @2, @"MGA": @0, @"MKD": @2, @"MMK": @0, @"MNT": @2,
            @"MOP": @2, @"MRO": @0, @"MUR": @2, @"MVR": @2, @"MWK": @2, @"MXN": @2, @"MXV": @2, @"MYR": @2,
            @"MZN": @2, @"NAD": @2, @"NGN": @2, @"NIO": @2, @"NOK": @2, @"NPR": @2, @"NZD": @2, @"OMR": @3,
            @"PAB": @2, @"PEN": @2, @"PGK": @2, @"PHP": @2, @"PKR": @2, @"PLN": @2, @"PYG": @0, @"QAR": @2,
            @"RON": @2, @"RSD": @2, @"RUB": @2, @"RWF": @0, @"SAR": @2, @"SBD": @2, @"SCR": @2, @"SDG": @2,
            @"SEK": @2, @"SGD": @2, @"SHP": @2, @"SLL": @0, @"SOS": @2, @"SRD": @2, @"SSP": @2, @"STD": @0,
            @"SYP": @2, @"SZL": @2, @"THB": @2, @"TJS": @2, @"TMT": @2, @"TND": @3, @"TOP": @2, @"TRY": @2,
            @"TTD": @2, @"TWD": @2, @"TZS": @2, @"UAH": @2, @"UGX": @2, @"USD": @2, @"USN": @2, @"USS": @2,
            @"UYI": @0, @"UYU": @2, @"UZS": @2, @"VEF": @2, @"VND": @0, @"VUV": @0, @"WST": @2, @"XAF": @0,
            @"XCD": @2, @"XOF": @0, @"XPF": @0, @"YER": @2, @"ZAR": @2, @"ZMW": @2,
        };
    });
    return currencyDigits;
}

- (NSString *)stringWithUnitForValue:(NSNumber *)value
                          inCurrency:(NSString *)currency {

    NSNumberFormatter *currencyNumberFormatter = [self createNumberFormatter];
    [self setFractionDigits:currency inCurrencyNumberFormatter:currencyNumberFormatter];
    currencyNumberFormatter.currencyCode = currency;
    currencyNumberFormatter.currencySymbol = self.currencySymbols[currency];
    currencyNumberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    [currencyNumberFormatter setNegativePrefix:@"-"];
    [currencyNumberFormatter setNegativeSuffix:@""];
    return [currencyNumberFormatter stringFromNumber:value];
}

- (NSString *)stringForValue:(NSNumber *)value
                  inCurrency:(NSString *)currency {

    NSNumberFormatter *currencyNumberFormatter = [self createNumberFormatter];
    [self setFractionDigits:currency inCurrencyNumberFormatter:currencyNumberFormatter];
    currencyNumberFormatter.currencyCode = nil;
    currencyNumberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    return [currencyNumberFormatter stringFromNumber:value];
}

- (NSDecimalNumber *)parseString:(NSString *)string error:(NSError **)error {

    string = [self cleanUpInputString:string];

    NSNumberFormatter *currencyNumberFormatter = [self createNumberFormatter];
    currencyNumberFormatter.generatesDecimalNumbers = YES;
    currencyNumberFormatter.lenient = YES;
    currencyNumberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    NSDecimalNumber *number = nil;
    if (error) {
        *error = nil;
    }
    if ([currencyNumberFormatter getObjectValue:&number
                                       forString:string
                                           range:NULL
                                           error:error]) {
        return number;
    } else {
        return 0ll;
    }
}

- (NSString *)cleanUpInputString:(NSString *)string {
    NSCharacterSet *numeric = [NSCharacterSet characterSetWithCharactersInString:@"-0123456789"];
    NSRange start = [string rangeOfCharacterFromSet:numeric];
    NSRange end = [string rangeOfCharacterFromSet:numeric options:NSBackwardsSearch];
    if (start.location == NSNotFound) {
        return string;
    } else {
        return [string substringWithRange:NSMakeRange(start.location, end.location - start.location + 1)];
    }
}

- (void)setFractionDigits:(NSString *)currency inCurrencyNumberFormatter:(NSNumberFormatter *)currencyNumberFormatter {
    int digits = [self.currencyDigits[currency] intValue];
    currencyNumberFormatter.minimumFractionDigits = digits;
    currencyNumberFormatter.maximumFractionDigits = digits;
}

- (NSNumberFormatter *)createNumberFormatter {
    NSNumberFormatter *currencyNumberFormatter = [NSNumberFormatter new];
    currencyNumberFormatter.formatterBehavior = NSNumberFormatterBehavior10_4;
    currencyNumberFormatter.locale = self.locale;
    currencyNumberFormatter.hasThousandSeparators = YES;
    return currencyNumberFormatter;
}

@end
