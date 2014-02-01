#import "NSDecimalNumber+HISatoshiConversion.h"

@implementation NSDecimalNumber(HISatoshiConversion)

+ (NSDecimalNumber *)hiDecimalNumberWithSatoshi:(satoshi_t)satoshi {
    return [NSDecimalNumber decimalNumberWithMantissa:ABS(satoshi)
                                             exponent:-8
                                           isNegative:satoshi < 0];
}

- (satoshi_t)hiSatoshi {
    return [self decimalNumberByMultiplyingByPowerOf10:8].unsignedLongLongValue;
}

@end
