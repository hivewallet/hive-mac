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


@implementation HITransaction

@dynamic id;
@dynamic amount;
@dynamic fee;
@dynamic senderName;
@dynamic senderHash;
@dynamic status;
@dynamic date;
@dynamic senderEmail;
@dynamic request;
@dynamic contact;
@dynamic sourceApplication;
@dynamic read;
@dynamic fiatAmount;
@dynamic fiatCurrency;
@dynamic fiatRate;
@dynamic label;
@dynamic details;
@dynamic paymentRequestURL;

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
    return (self.amount >= 0) ? HITransactionDirectionIncoming : HITransactionDirectionOutgoing;
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
