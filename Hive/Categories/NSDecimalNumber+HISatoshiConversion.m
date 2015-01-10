#import "NSDecimalNumber+HISatoshiConversion.h"

static NSDecimalNumberHandler *_satoshiRoundingBehavior;

@implementation NSDecimalNumber(HISatoshiConversion)

+ (void)load {
    // workaround for a NSDecimalNumber bug in Yosemite
    _satoshiRoundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                                                                      scale:0
                                                                           raiseOnExactness:NO
                                                                            raiseOnOverflow:NO
                                                                           raiseOnUnderflow:NO
                                                                        raiseOnDivideByZero:NO];
}

+ (NSDecimalNumber *)hiDecimalNumberWithSatoshi:(satoshi_t)satoshi {
    return [NSDecimalNumber decimalNumberWithMantissa:ABS(satoshi)
                                             exponent:-8
                                           isNegative:satoshi < 0];
}

- (satoshi_t)hiSatoshi {
    NSDecimalNumber *satoshiAmount = [self decimalNumberByMultiplyingByPowerOf10:8];
    return [[satoshiAmount decimalNumberByRoundingAccordingToBehavior:_satoshiRoundingBehavior] unsignedLongLongValue];
}

@end
