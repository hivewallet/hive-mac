//
//  HIProfileViewController.m
//  Hive
//
//  Created by Jakub Suder on 30.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HICurrencyAmountFormatter.h"
#import "HIProfile.h"
#import "HIContactInfoViewController.h"
#import "HIProfileViewController.h"
#import "NSColor+Hive.h"

@interface HIProfileViewController () {
    HIProfile *_profile;
    HICurrencyAmountFormatter *_amountFormatter;
    HIContactInfoViewController *_infoPanel;
}

@end

@implementation HIProfileViewController

- (id)init {
    self = [super initWithNibName:@"HIProfileViewController" bundle:nil];

    if (self)
    {
        self.iconName = @"your-profile";

        _profile = [HIProfile new];
        _amountFormatter = [[HICurrencyAmountFormatter alloc] init];
        _infoPanel = [[HIContactInfoViewController alloc] initWithParent:self];

        [[BCClient sharedClient] addObserver:self
                                  forKeyPath:@"balance"
                                     options:NSKeyValueObservingOptionInitial
                                     context:NULL];
        [[BCClient sharedClient] addObserver:self
                                  forKeyPath:@"pendingBalance"
                                     options:NSKeyValueObservingOptionInitial
                                     context:NULL];
    }

    return self;
}

- (void)dealloc
{
    [[BCClient sharedClient] removeObserver:self forKeyPath:@"balance"];
    [[BCClient sharedClient] removeObserver:self forKeyPath:@"pendingBalance"];
}

- (void)loadView {
    [super loadView];
    [_infoPanel loadView];

    self.view.layer.backgroundColor = [[NSColor hiWindowBackgroundColor] hiNativeColor];

    [self updateBalance];
    [self refreshData];

    [self showControllerInContentView:_infoPanel];
}

- (void)viewWillAppear
{
    [self refreshData];
}

- (void)refreshData
{
    self.title = NSLocalizedString(@"Profile", @"Profile view title string");

    self.nameLabel.stringValue = _profile.name;
    self.photoView.image = _profile.avatarImage;

    [_infoPanel configureViewForContact:_profile];
}

- (void)showControllerInContentView:(NSViewController *)controller
{
    [[_contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    NSRect f = controller.view.frame;
    f.origin.x = 0;
    f.origin.y = 0;
    f.size.width = _contentView.bounds.size.width;
    f.size.height = _contentView.bounds.size.height;
    controller.view.frame = f;

    [_contentView addSubview:controller.view];
}

- (void)updateBalance
{
    NSDecimalNumber *balance = [NSDecimalNumber decimalNumberWithMantissa:[[BCClient sharedClient] balance]
                                                                 exponent:-8
                                                               isNegative:NO];

    NSDecimalNumber *pending = [NSDecimalNumber decimalNumberWithMantissa:[[BCClient sharedClient] pendingBalance]
                                                                 exponent:-8
                                                               isNegative:NO];

    if ([pending isGreaterThan:[NSDecimalNumber decimalNumberWithString:@"0"]])
    {
        self.balanceLabel.stringValue = [NSString stringWithFormat:@"%@ (+%@ %@)",
                                                                   [_amountFormatter stringFromNumber:balance],
                                                                   [_amountFormatter stringFromNumber:pending],
                                                                   NSLocalizedString(@"pending",
                                                                   @"part of the balance amount that isn't available")];
    }
    else
    {
        self.balanceLabel.stringValue = [_amountFormatter stringFromNumber:balance];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == [BCClient sharedClient])
    {
        if ([keyPath isEqual:@"balance"] || [keyPath isEqual:@"pendingBalance"])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateBalance];
            });
        }
    }
}

@end
