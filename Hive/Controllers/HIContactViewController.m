//
//  HIContactViewController.m
//  Hive
//
//  Created by Jakub Suder on 30.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIContactInfoViewController.h"
#import "HIContactViewController.h"
#import "HINameFormatService.h"
#import "HISendBitcoinsWindowController.h"
#import "HITransactionsViewController.h"
#import "NSColor+Hive.h"

@interface HIContactViewController ()<HINameFormatServiceObserver> {
    HIContact *_contact;
    HIContactInfoViewController *_infoPanel;
    NSArray *_panelControllers;
}

@property (nonatomic, weak) IBOutlet NSImageView *photoView;
@property (nonatomic, weak) IBOutlet NSTextField *nameLabel;
@property (nonatomic, weak) IBOutlet NSButton *sendBitcoinButton;
@property (nonatomic, weak) IBOutlet HIProfileTabView *tabView;
@property (nonatomic, weak) IBOutlet NSView *contentView;

// top-level objects
@property (nonatomic, strong) IBOutlet HIContactTabBarController *tabBarController;

@end

@implementation HIContactViewController

- (instancetype)initWithContact:(HIContact *)contact {
    self = [super initWithNibName:@"HIContactViewController" bundle:nil];

    if (self) {
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

    [self.tabBarController selectTabAtIndex:0];
}

- (void)viewWillAppear {
    [self refreshData];
    [[HINameFormatService sharedService] addObserver:self];
}

- (void)viewWillDisappear {
    [[HINameFormatService sharedService] removeObserver:self];
}

- (void)refreshData {
    self.title = _contact.name;

    self.nameLabel.stringValue = _contact.name;
    self.photoView.image = _contact.avatarImage;

    [_infoPanel configureViewForContact:_contact];

    [self.sendBitcoinButton setEnabled:(_contact.addresses.count > 0)];
}

- (void)controller:(HIContactTabBarController *)controller switchedToTabIndex:(NSInteger)index {
    if (index < _panelControllers.count) {
        [self showControllerInContentView:_panelControllers[index]];
    }
}

- (void)showControllerInContentView:(NSViewController *)controller {
    [[_contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    controller.view.frame = _contentView.bounds;
    [_contentView addSubview:controller.view];
}

- (IBAction)sendBitcoinsPressed:(id)sender {
    HISendBitcoinsWindowController *window = [[NSApp delegate] sendBitcoinsWindowForContact:_contact];
    [window showWindow:self];
}

#pragma mark - HINameFormatServiceObserver

- (void)nameFormatDidChange {
    [self refreshData];
}

@end
