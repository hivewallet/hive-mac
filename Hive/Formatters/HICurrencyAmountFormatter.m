//
//  HICurrencyAmountFormatter.m
//  Hive
//
//  Created by Jakub Suder on 05.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HICurrencyAmountFormatter.h"

@implementation HICurrencyAmountFormatter

- (void)awakeFromNib {
    self.generatesDecimalNumbers = YES;
    self.minimum = @0;
    self.minimumFractionDigits = 2;
    self.maximumFractionDigits = 8;
    self.numberStyle = NSNumberFormatterDecimalStyle;
    self.localizesFormat = YES;
}

- (id)init {
    self = [super init];

    if (self) {
        [self awakeFromNib];
    }

    return self;
}

- (BOOL)isPartialStringValid:(NSString*)partialString
            newEditingString:(NSString**)newString
            errorDescription:(NSString**)error {

    if (partialString.length == 0) {
        return YES;
    }

    NSString *text = [partialString stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSNumber *value = [self numberFromString:text];

    if (value) {
        return YES;
    } else {
        NSBeep();
        return NO;
    }
}

@end
