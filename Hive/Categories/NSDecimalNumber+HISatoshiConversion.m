#import "NSDecimalNumber+HISatoshiConversion.h"

@implementation NSDecimalNumber(HISatoshiConversion)

+ (NSDecimalNumber *)hiDecimalNumberWithSatoshi:(satoshi_t)satoshi {
    return [NSDecimalNumber decimalNumberWithMantissa:satoshi
                                             exponent:-8
                                           isNegative:NO];
}

- (satoshi_t)hiSatoshi {
    return [self decimalNumberByMultiplyingByPowerOf10:8].unsignedLongLongValue;
}

@end
