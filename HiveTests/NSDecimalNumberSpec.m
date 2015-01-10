//
//  NSDecimalNumberSpec.m
//  Hive
//
//  Created by Jakub Suder on 10/01/15.
//  Copyright (c) 2015 Hive Developers. All rights reserved.
//

#import "NSDecimalNumber+HISatoshiConversion.h"

SPEC_BEGIN(NSDecimalNumberSpec)

describe(@"hiSatoshi", ^{
    it(@"should return the amount in satoshi", ^{
        NSDecimalNumber *num = [NSDecimalNumber decimalNumberWithString:@"25"];

        assertThatUnsignedLongLong([num hiSatoshi], is(equalToUnsignedLongLong(2500000000)));
    });

    context(@"for numbers with a fractional part", ^{
        it(@"should return a correct value", ^{
            NSDecimalNumber *num = [NSDecimalNumber decimalNumberWithString:@"6.251"];

            assertThatUnsignedLongLong([num hiSatoshi], is(equalToUnsignedLongLong(625100000)));
        });
    });

    context(@"for numbers with fractions of satoshi", ^{
        it(@"should return a rounded value", ^{
            NSDecimalNumber *num = [NSDecimalNumber decimalNumberWithString:@"11.234200989"];

            assertThatUnsignedLongLong([num hiSatoshi], is(equalToUnsignedLongLong(1123420099)));
        });
    });

    context(@"for numbers with a very long fractional part", ^{
        it(@"should return a rounded value", ^{
            NSDecimalNumber *num = [NSDecimalNumber decimalNumberWithString:@"3045.001122334455667788"];

            assertThatUnsignedLongLong([num hiSatoshi], is(equalToUnsignedLongLong(304500112233)));
        });
    });
});

SPEC_END
