//
//  HIBitcoinURI.m
//  Hive
//
//  Created by Jakub Suder on 23.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <BitcoinJKit/HIBitcoinManager.h>
#import "HIBitcoinURI.h"
#import "NSDecimalNumber+HISatoshiConversion.h"

static NSString * const BitcoinURIPrefix = @"bitcoin:";

@implementation HIBitcoinURI

- (instancetype)initWithURIString:(NSString *)URI {
    self = [super init];

    if (self) {
        _URIString = URI;

        if ([URI hasPrefix:BitcoinURIPrefix]) {
            [self extractFields];
            _valid = [self validate];
        } else if ([self looksLikeBitcoinAddress:URI]) {
            _address = [URI copy];
            _valid = [[HIBitcoinManager defaultManager] isAddressValid:_address];
        } else {
            return nil;
        }
    }

    return self;
}

- (BOOL)looksLikeBitcoinAddress:(NSString *)URI {
    return [[URI stringByTrimmingCharactersInSet:[NSCharacterSet alphanumericCharacterSet]] isEqual:@""];
}

- (void)extractFields {
    NSRange questionMark = [self.URIString rangeOfString:@"?"];
    NSString *base;

    if (questionMark.location == NSNotFound) {
        base = [self.URIString copy];
    } else {
        NSString *parameterString = [self.URIString substringFromIndex:(questionMark.location + 1)];
        _parameters = [self parseParameterString:parameterString];
        base = [self.URIString substringToIndex:questionMark.location];
    }

    _address = [base substringFromIndex:BitcoinURIPrefix.length];
    _label = self.parameters[@"label"];
    _message = self.parameters[@"message"];
    _paymentRequestURL = self.parameters[@"r"];

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
    return [NSString stringWithFormat:@"<BitcoinURI: %p, valid = %d, address = %@, amount = %lld, parameters = %@>",
            self, _valid, _address, _amount, _parameters];
}

@end
