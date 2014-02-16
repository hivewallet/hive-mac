//
//  HISidebarController.m
//  Hive
//
//  Created by Jakub Suder on 30.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HISidebarButton.h"
#import "HISidebarController.h"
#import "HIViewController.h"

// This magic number must match the sidebar width in the XIB.
// TODO: There should be a constraint so this is just a single value!
const NSInteger SidebarButtonWidth = 72;
const NSInteger SidebarButtonHeight = 52;

static const NSInteger SidebarButtonTagStart = 1000;
static const NSInteger SidebarIndexNotSelected = -1;

@interface HISidebarController () {
    NSMutableArray *_barButtons;
    NSMutableArray *_viewControllers;
}

@property (strong, nonatomic) IBOutlet NSView *view;
@property (assign, nonatomic) NSUInteger selectedTabIndex;

@end

@implementation HISidebarController

- (void)awakeFromNib {
    self.selectedTabIndex = SidebarIndexNotSelected;

    _barButtons = [[NSMutableArray alloc] init];
    _viewControllers = [[NSMutableArray alloc] init];
}

- (void)addViewController:(HIViewController *)controller {
    [_viewControllers addObject:controller];

    NSButton *button = [self tabBarButtonForController:controller];
    [_barButtons addObject:button];
    [self.view addSubview:button];

    if (_barButtons.count == 1) {
        [self selectControllerAtIndex:0];
    }
}

- (NSButton *)tabBarButtonForController:(HIViewController *)controller {
    NSInteger position = _barButtons.count;
    CGFloat positionY = self.view.bounds.size.height - (position + 1) * SidebarButtonHeight;
    NSRect frame = NSMakeRect(0, positionY, SidebarButtonWidth, SidebarButtonHeight);

    NSButton *button = [[HISidebarButton alloc] initWithFrame: frame];
    button.buttonType = NSToggleButton;
    button.bordered = NO;
    button.tag = SidebarButtonTagStart + position;
    button.image = [self iconForController:controller active:NO];
    button.alternateImage = [self iconForController:controller active:YES];
    button.target = self;
    button.action = @selector(tabBarClicked:);
    button.autoresizingMask = NSViewMinYMargin;
    button.keyEquivalentModifierMask = NSCommandKeyMask;
    button.keyEquivalent = [NSString stringWithFormat:@"%ld", position + 1];
    return button;
}

- (void)tabBarClicked:(NSButton *)tabButton {
    NSInteger position = tabButton.tag - SidebarButtonTagStart;
    [self selectControllerAtIndex:position];
}

- (void)selectControllerAtIndex:(NSInteger)index {
    [_barButtons[index] setState:NSOnState];

    NSInteger previousIndex = self.selectedTabIndex;
    self.selectedTabIndex = index;

    BOOL clickedAgain = (previousIndex == index);

    if (previousIndex != SidebarIndexNotSelected && !clickedAgain) {
        [_barButtons[previousIndex] setState:NSOffState];
    }

    HIViewController *selectedController = _viewControllers[index];
    [self.delegate sidebarDidSelectController:selectedController again:clickedAgain];
}

- (NSImage *)iconForController:(HIViewController *)controller active:(BOOL)active {
    NSString *variant = active ? @"active" : @"inactive";
    NSString *iconName = [NSString stringWithFormat:@"icon-%@__%@", controller.iconName, variant];
    return [NSImage imageNamed:iconName];
}

@end
