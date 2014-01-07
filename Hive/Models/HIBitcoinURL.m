//
//  HIBitcoinURL.m
//  Hive
//
//  Created by Jakub Suder on 23.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIBitcoinURL.h"

#import "NSDecimalNumber+HISatoshiConversion.h"

static NSString * const BitcoinURLPrefix = @"bitcoin:";

@implementation HIBitcoinURL

- (id)initWithURLString:(NSString *)URL {
    self = [super init];

    if (self) {
        _URLString = URL;

        if (![URL hasPrefix:BitcoinURLPrefix]) {
            return nil;
        }

        [self extractFields];

        _valid = [self validate];
    }

    return self;
}

- (void)extractFields {
    NSRange questionMark = [self.URLString rangeOfString:@"?"];
    NSString *base;

    if (questionMark.location == NSNotFound) {
        base = [self.URLString copy];
    } else {
        NSString *parameterString = [self.URLString substringFromIndex:(questionMark.location + 1)];
        _parameters = [self parseParameterString:parameterString];
        base = [self.URLString substringToIndex:questionMark.location];
    }

    _address = [base substringFromIndex:BitcoinURLPrefix.length];
    _label = self.parameters[@"label"];
    _message = self.parameters[@"message"];

    NSString *amountParameter = self.parameters[@"amount"];
    _amount = amountParameter ? [NSDecimalNumber decimalNumberWithString:amountParameter].hiSatoshi : 0;
}

- (BOOL)validate {
    for (NSString *key in self.parameters.allKeys) {
        if ([key hasPrefix:@"req-"]) {
            return NO;
        }
    }

    return YES;
}

- (NSDictionary *)parseParameterString:(NSString *)string {
    NSArray *tokens = [string componentsSeparatedByString:@"&"];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:tokens.count];

    for (NSString *token in tokens) {
        NSArray *parts = [token componentsSeparatedByString:@"="];

        if (parts.count == 2) {
            parameters[parts[0]] = [parts[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
    }

    return parameters;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<BitcoinURL: %p, valid = %d, address = %@, amount = %lld, parameters = %@>",
            self, _valid, _address, _amount, _parameters];
}

@end
