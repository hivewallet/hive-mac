//
//  HITransaction.m
//  Hive
//
//  Created by Bazyli Zygan on 18.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIContact.h"
#import "HIDatabaseManager.h"
#import "HITransaction.h"
#import "HIApplication.h"

NSString * const HITransactionEntity = @"HITransaction";
NSString * const HITransactionDirectionUnknownException = @"HITransactionDirectionUnknownException";

@implementation HITransaction

@dynamic id;
@dynamic amount;
@dynamic contact;
@dynamic date;
@dynamic details;
@dynamic fee;
@dynamic fiatAmount;
@dynamic fiatCurrency;
@dynamic fiatRate;
@dynamic label;
@dynamic read;
@dynamic paymentRequestURL;
@dynamic senderHash;
@dynamic sourceApplication;
@dynamic status;


+ (BOOL)isAmountWithinExpectedRange:(satoshi_t)amount {
    // get previous transaction amounts (sent only)
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HITransactionEntity];
    request.predicate = [NSPredicate predicateWithFormat:@"amount < 0"];
    request.propertiesToFetch = @[@"amount"];
    request.resultType = NSDictionaryResultType;

    NSError *error = nil;
    NSArray *result = [DBM executeFetchRequest:request error:&error];

    if (error) {
        HILogWarn(@"Error while calculating average amount: %@", error);

        // this isn't critical enough to block sending
        return YES;
    }

    if (result.count < 3) {
        // we need some data first to be able to say if the amount is suspicious
        return YES;
    }

    // calculate average and standard deviation
    NSArray *amounts = [result valueForKey:@"amount"];
    double average = [[amounts valueForKeyPath:@"@avg.self"] doubleValue];

    NSExpression *amountsArgument = [NSExpression expressionForConstantValue:amounts];
    NSExpression *stdDevCalculator = [NSExpression expressionForFunction:@"stddev:" arguments:@[amountsArgument]];
    double stdDev = [[stdDevCalculator expressionValueWithObject:nil context:nil] doubleValue];

    return (amount <= fabs(average) + stdDev);
}

- (HITransactionDirection)direction {
    if (self.amount > 0) {
        return HITransactionDirectionIncoming;
    } else if (self.amount < 0) {
        return HITransactionDirectionOutgoing;
    } else {
        @throw [NSException exceptionWithName:HITransactionDirectionUnknownException
                                       reason:@"Transaction direction cannot be determined since its amount is 0"
                                     userInfo:nil];
    }
}

- (BOOL)isIncoming {
    return (self.direction == HITransactionDirectionIncoming);
}

- (BOOL)isOutgoing {
    return (self.direction == HITransactionDirectionOutgoing);
}

- (uint64_t)absoluteAmount {
    return llabs(self.amount) - (self.isOutgoing ? self.fee : 0);
}

- (NSString *)targetAddress {
    return self.senderHash;
}

@end
