//
//  HIFeeDetailsViewController.m
//  Hive
//
//  Created by Nikolaj Schumacher on 2013-11-30.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIFeeDetailsViewController.h"

#import "HIBitcoinFormatService.h"

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

- (void)setFee:(satoshi_t)fee {
    _fee = fee;
    [self updateFeeLabel];
}

- (void)setBitcoinFormat:(NSString *)bitcoinFormat {
    _bitcoinFormat = [bitcoinFormat copy];
    [self updateFeeLabel];
}

- (void)updateFeeLabel {
    if (self.bitcoinFormat && self.fee) {
        self.feeLabel.stringValue = [[HIBitcoinFormatService sharedService] stringForBitcoin:self.fee
                                                                                  withFormat:self.bitcoinFormat];
    }
}


@end
