#import "HIBitcoinFormatService.h"

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

@end
