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
#import "HISendBitcoinsWindowController.h"
#import "HITransactionsViewController.h"
#import "NSColor+Hive.h"

@interface HIProfileViewController () {
    HIContact *_contact;
    HICurrencyAmountFormatter *_amountFormatter;
    HIContactInfoViewController *_infoPanel;
    NSArray *_panelControllers;
}

@end

@implementation HIProfileViewController

- (id)initWithContact:(HIContact *)contact {
    self = [super initWithNibName:@"HIProfileViewController" bundle:nil];

    if (self)
    {
        self.iconName = @"your-profile";

        _contact = contact;
        _amountFormatter = [[HICurrencyAmountFormatter alloc] init];
        _infoPanel = [[HIContactInfoViewController alloc] initWithParent:self];

        if ([contact isKindOfClass:[HIContact class]])
        {
            _panelControllers = @[_infoPanel, [[HITransactionsViewController alloc] initWithContact:_contact]];
        }
        else
        {
            [[BCClient sharedClient] addObserver:self
                                      forKeyPath:@"balance"
                                         options:NSKeyValueObservingOptionInitial
                                         context:NULL];
            [[BCClient sharedClient] addObserver:self
                                      forKeyPath:@"pendingBalance"
                                         options:NSKeyValueObservingOptionInitial
                                         context:NULL];
        }
    }

    return self;
}

- (void)dealloc
{
    if ([_contact isKindOfClass:[HIProfile class]])
    {
        [[BCClient sharedClient] removeObserver:self forKeyPath:@"balance"];
        [[BCClient sharedClient] removeObserver:self forKeyPath:@"pendingBalance"];
    }
}

- (void)loadView {
    [super loadView];
    [_infoPanel loadView];

    self.view.layer.backgroundColor = [[NSColor hiWindowBackgroundColor] hiNativeColor];

    [self configureView];
    [self refreshData];

    if (self.tabView.isHidden)
    {
        [self showControllerInContentView:_infoPanel];
    }
    else
    {
        [self.tabBarController selectTabAtIndex:0];
    }
}

- (void)viewWillAppear
{
    [self refreshData];
}

- (void)configureView
{
    if ([_contact isKindOfClass:[HIContact class]])
    {
        [self.sendBitcoinButton setHidden:NO];
    }
    else
    {
        // make contentView fill whole area below the header
        NSRect f = self.contentView.frame;
        f.origin.y = 0;
        f.size.height = self.view.bounds.size.height - 78;
        f.size.width = self.view.bounds.size.width;
        self.contentView.frame = f;

        // show account balance
        [self.tabView setHidden:YES];
        [self.bitcoinSymbol setHidden:NO];
        [self.balanceLabel setHidden:NO];
        [self updateBalance];

        // add a separator above the balance
        NSRect separatorFrame = NSMakeRect(self.photoView.frame.size.width + 15,
            self.view.frame.size.height - self.photoView.frame.size.height / 2,
            self.view.frame.size.width - self.photoView.frame.size.width - 30,
            1);
        [self.view addSubview:[self separatorViewWithFrame:separatorFrame]];

        // add a separator below the header (since there's no tab bar)
        separatorFrame = NSMakeRect(0,
            self.view.frame.size.height - self.photoView.frame.size.height,
            self.view.frame.size.width,
            1);
        [self.view addSubview:[self separatorViewWithFrame:separatorFrame]];
    }
}

- (void)refreshData
{
    if ([_contact isKindOfClass:[HIContact class]])
    {
        self.title = _contact.name;
    }
    else
    {
        self.title = NSLocalizedString(@"Profile", @"Profile view title string");
    }

    self.nameLabel.stringValue = _contact.name;
    self.photoView.image = _contact.avatarImage;

    [_infoPanel configureViewForContact:_contact];
}

- (NSView *)separatorViewWithFrame:(NSRect)frame
{
    NSView *separator = [[NSView alloc] initWithFrame:frame];
    separator.autoresizingMask = NSViewMinYMargin | NSViewWidthSizable;
    separator.wantsLayer = YES;
    separator.layer.backgroundColor = [[NSColor colorWithCalibratedWhite:0.75 alpha:1.0] hiNativeColor];
    return separator;
}

- (void)controller:(HIContactTabBarController *)controller switchedToTabIndex:(NSInteger)index
{
    if (index < _panelControllers.count)
    {
        [self showControllerInContentView:_panelControllers[index]];
    }
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

- (IBAction)sendBitcoinsPressed:(id)sender
{
    HISendBitcoinsWindowController *window = [[NSApp delegate] sendBitcoinsWindowForContact:_contact];
    [window showWindow:self];
}

@end
