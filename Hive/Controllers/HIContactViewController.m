//
//  HIContactViewController.m
//  Hive
//
//  Created by Jakub Suder on 30.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIContactInfoViewController.h"
#import "HIContactViewController.h"
#import "HISendBitcoinsWindowController.h"
#import "HITransactionsViewController.h"
#import "NSColor+Hive.h"

@interface HIContactViewController () {
    HIContact *_contact;
    HIContactInfoViewController *_infoPanel;
    NSArray *_panelControllers;
}

@end

@implementation HIContactViewController

- (id)initWithContact:(HIContact *)contact {
    self = [super initWithNibName:@"HIContactViewController" bundle:nil];

    if (self)
    {
        self.iconName = @"your-profile";

        _contact = contact;
        _infoPanel = [[HIContactInfoViewController alloc] initWithParent:self];

        _panelControllers = @[_infoPanel, [[HITransactionsViewController alloc] initWithContact:_contact]];
    }

    return self;
}

- (void)loadView {
    [super loadView];
    [_infoPanel loadView];

    self.view.layer.backgroundColor = [[NSColor hiWindowBackgroundColor] hiNativeColor];

    [self refreshData];

    [self.tabBarController selectTabAtIndex:0];
}

- (void)viewWillAppear
{
    [self refreshData];
}

- (void)refreshData
{
    self.title = _contact.name;

    self.nameLabel.stringValue = _contact.name;
    self.photoView.image = _contact.avatarImage;

    [_infoPanel configureViewForContact:_contact];
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

- (IBAction)sendBitcoinsPressed:(id)sender
{
    HISendBitcoinsWindowController *window = [[NSApp delegate] sendBitcoinsWindowForContact:_contact];
    [window showWindow:self];
}

@end
