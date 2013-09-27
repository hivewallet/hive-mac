//
//  HIProfileViewController.m
//  Hive
//
//  Created by Jakub Suder on 30.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HICurrencyAmountFormatter.h"
#import "HIProfileInfoViewController.h"
#import "HIProfileViewController.h"
#import "HISendBitcoinsWindowController.h"
#import "HITransactionsViewController.h"
#import "NSColor+NativeColor.h"

@interface HIProfileViewController () {
    HIContact *_contact;
    HICurrencyAmountFormatter *_amountFormatter;
    HIProfileInfoViewController *_infoPanel;
    NSArray *_panelControllers;
}

@end

@implementation HIProfileViewController

- (id)init
{
    self = [super initWithNibName:@"HIProfileViewController" bundle:nil];

    if (self)
    {
        self.iconName = @"your-profile";
        self.title = NSLocalizedString(@"Profile", @"Profile view title string");        

        _infoPanel = [[HIProfileInfoViewController alloc] initWithParent:self];
        _amountFormatter = [[HICurrencyAmountFormatter alloc] init];

        [[BCClient sharedClient] addObserver:self
                                  forKeyPath:@"balance"
                                     options:NSKeyValueObservingOptionInitial
                                     context:NULL];
    }

    return self;
}

- (id)initWithContact:(HIContact *)contact {
    self = [self init];

    if (self) {
        _contact = contact;
        self.title = _contact.name;

        _panelControllers = @[[[HITransactionsViewController alloc] initWithContact:_contact], _infoPanel];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contactHasChanged:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:nil];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)contactHasChanged:(NSNotification *)notification
{
    if (!_contact)
    {
        return;
    }

    NSArray *updatedObjects = notification.userInfo[NSUpdatedObjectsKey];

    for (NSManagedObject *object in updatedObjects)
    {
        if (object == _contact)
        {
            [self configureViewForContact];
            return;
        }
    }
}

- (void)loadView {
    [super loadView];
    [_infoPanel loadView];

    self.view.layer.backgroundColor = [[NSColor colorWithCalibratedWhite:0.9 alpha:1.0] NativeColor];

    if (_contact)
    {
        [self configureViewForContact];
    }
    else
    {
        [self configureViewForOwner];
    }

    [self showControllerInContentView:_infoPanel];
}

- (void)configureViewForContact
{
    self.nameLabel.stringValue = _contact.name;
    self.photoView.image = _contact.avatarImage;

    [_infoPanel configureViewForContact:_contact];

    [self.sendBitcoinButton setHidden:NO];
}

- (void)configureViewForOwner
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

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults objectForKey:@"firstName"] || [defaults objectForKey:@"lastName"])
    {
        self.nameLabel.stringValue = [NSString stringWithFormat:@"%@ %@",
                                      [defaults objectForKey:@"firstName"],
                                      [defaults objectForKey:@"lastName"]];
    }
    else
    {
        self.nameLabel.stringValue = NSLocalizedString(@"Anonymous", @"Anonymous username for profile page");
    }

    if ([defaults objectForKey:@"avatarData"])
    {
        self.photoView.image = [[NSImage alloc] initWithData:[defaults objectForKey:@"avatarData"]];
    }
    else
    {
        self.photoView.image = [NSImage imageNamed:@"avatar-empty"];
    }

    [_infoPanel configureViewForOwner];
    [self showControllerInContentView:_infoPanel];
}

- (NSView *)separatorViewWithFrame:(NSRect)frame
{
    NSView *separator = [[NSView alloc] initWithFrame:frame];
    separator.autoresizingMask = NSViewMinYMargin | NSViewWidthSizable;
    separator.wantsLayer = YES;
    separator.layer.backgroundColor = [[NSColor colorWithCalibratedWhite:0.75 alpha:1.0] NativeColor];
    return separator;
}

- (void)controller:(HIProfileTabBarController *)controller switchedToTabIndex:(NSInteger)index
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
    double balance = [[BCClient sharedClient] balance] * 1.0 / SATOSHI;
    self.balanceLabel.stringValue = [_amountFormatter stringFromNumber:@(balance)];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == [BCClient sharedClient])
    {
        if ([keyPath isEqual:@"balance"])
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
