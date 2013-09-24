//
//  HIProfileViewController.m
//  Hive
//
//  Created by Jakub Suder on 30.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIProfileInfoViewController.h"
#import "HIProfileViewController.h"
#import "HISendBitcoinsWindowController.h"

@interface HIProfileViewController () {
    HIContact *_contact;
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
        _panelControllers = @[_infoPanel, [[NSViewController alloc] init]];
    }

    return self;
}

- (id)initWithContact:(HIContact *)contact {
    self = [self init];

    if (self) {
        _contact = contact;
        self.title = _contact.name;

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

    if (_contact)
    {
        [self configureViewForContact];
    }
    else
    {
        [self configureViewForOwner];
    }

    [self showControllerInContentView:_panelControllers[0]];
}

- (void)configureViewForContact
{
    self.nameLabel.stringValue = _contact.name;
    self.photoView.image = _contact.avatarImage;

    [_infoPanel configureViewForContact:_contact];
}

- (void)configureViewForOwner
{
    // move nameLabel down
    NSRect f = self.nameLabel.frame;
    f.origin.y -= 15;
    self.nameLabel.frame = f;

    // make contentView fill whole area below the header
    f = self.contentView.frame;
    f.origin.y = 0;
    f.size.height = self.view.bounds.size.height - 78;
    f.size.width = self.view.bounds.size.width;
    self.contentView.frame = f;

    [self.sendBtcBtn setHidden:YES];
    [self.tabView setHidden:YES];

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

- (IBAction)sendBitcoinsPressed:(id)sender
{
    HISendBitcoinsWindowController *window = [[NSApp delegate] sendBitcoinsWindowForContact:_contact];
    [window showWindow:self];
}

@end
