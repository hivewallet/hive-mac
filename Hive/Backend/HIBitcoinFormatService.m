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
    return [self.availableFormats containsObject:currency] ? currency : @"BTC";
}

- (void)setPreferredFormat:(NSString *)preferredFormat {
    [[NSUserDefaults standardUserDefaults] setObject:preferredFormat
                                              forKey:HIFormatPreferenceKey];
}

@end
