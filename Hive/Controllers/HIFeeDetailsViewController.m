//
//  HIFeeDetailsViewController.m
//  Hive
//
//  Created by Nikolaj Schumacher on 2013-11-30.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIFeeDetailsViewController.h"

#import "HICurrencyAmountFormatter.h"

@interface HIFeeDetailsViewController ()

@property (nonatomic, strong) IBOutlet NSTextField *feeLabel;

@end

@implementation HIFeeDetailsViewController

- (id)init {
    return [self initWithNibName:[self className] bundle:nil];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self updateFeeLabel];
}

- (void)setFee:(NSDecimalNumber *)fee {
    _fee = [fee copy];
    [self updateFeeLabel];
}

- (void)updateFeeLabel {
    self.feeLabel.stringValue = [[HICurrencyAmountFormatter new] stringFromNumber:self.fee];
}


@end
