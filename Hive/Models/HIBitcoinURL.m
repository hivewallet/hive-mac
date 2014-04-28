//
//  HIBitcoinURL.m
//  Hive
//
//  Created by Jakub Suder on 23.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <BitcoinJKit/HIBitcoinManager.h>
#import "HIBitcoinURL.h"
#import "NSDecimalNumber+HISatoshiConversion.h"

static NSString * const BitcoinURLPrefix = @"bitcoin:";

@implementation HIBitcoinURL

- (id)initWithURLString:(NSString *)URL {
    self = [super init];

    if (self) {
        _URLString = URL;

        if ([URL hasPrefix:BitcoinURLPrefix]) {
            [self extractFields];
            _valid = [self validate];
        } else if ([self looksLikeBitcoinAddress:URL]) {
            _address = [URL copy];
            _valid = [[HIBitcoinManager defaultManager] isAddressValid:_address];
        } else {
            return nil;
        }
    }

    return self;
}

- (BOOL)looksLikeBitcoinAddress:(NSString *)URL {
    return [[URL stringByTrimmingCharactersInSet:[NSCharacterSet alphanumericCharacterSet]] isEqual:@""];
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
    if (amountParameter) {
        NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:amountParameter];
        if (amount && amount != [NSDecimalNumber notANumber]) {
            _amount = [amount hiSatoshi];
        } else {
            HILogWarn(@"Amount '%@' is not a valid number.", amountParameter);
        }
    }
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
