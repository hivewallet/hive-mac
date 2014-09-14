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
#import "NSColor+Hive.h"
#import "KWExample.h"

static int KVO_CONTEXT;

static NSString *const KEY_BADGE_NUMBER = @"badgeNumber";

// This magic number must match the sidebar width in the XIB.
// TODO: There should be a constraint so this is just a single value!
const NSInteger SidebarButtonWidth = 72;
const NSInteger SidebarButtonHeight = 52;

static const NSInteger SidebarButtonTagStart = 1000;
static const NSInteger SidebarIndexNotSelected = -1;

@interface HISidebarController () {
    NSMutableArray *_barButtons;
    NSMutableArray *_badges;
    NSMutableArray *_viewControllers;
}

@property (weak, nonatomic) IBOutlet NSView *view;
@property (weak, nonatomic) IBOutlet NSButton *sendButton;
@property (unsafe_unretained, nonatomic) IBOutlet id<HISidebarControllerDelegate> delegate;

@property (assign, nonatomic) NSInteger selectedTabIndex;

@end

@implementation HISidebarController

- (void)awakeFromNib {
    self.selectedTabIndex = SidebarIndexNotSelected;

    _barButtons = [[NSMutableArray alloc] init];
    _badges = [[NSMutableArray alloc] init];
    _viewControllers = [[NSMutableArray alloc] init];
}

- (void)dealloc {
    [self removeBadgeObservers];
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;

    for (NSButton *button in _barButtons) {
        [button setEnabled:enabled];
    }

    [self.sendButton setHidden:!enabled];
}

- (void)addViewController:(HIViewController *)controller {
    [_viewControllers addObject:controller];

    NSButton *button = [self tabBarButtonForController:controller];
    [_barButtons addObject:button];
    [self.view addSubview:button];

    [self addBadgeForButton:button controller:controller];
}

- (NSButton *)tabBarButtonForController:(HIViewController *)controller {
    NSInteger position = _barButtons.count;
    CGFloat positionY = self.view.bounds.size.height - (position + 1) * SidebarButtonHeight;
    NSRect frame = NSMakeRect(0, positionY, SidebarButtonWidth, SidebarButtonHeight);

    NSButton *button = [[HISidebarButton alloc] initWithFrame: frame];
    button.buttonType = NSToggleButton;
    button.bordered = NO;
    button.enabled = self.enabled;
    button.tag = SidebarButtonTagStart + position;
    button.image = [self iconForController:controller active:NO];
    button.alternateImage = [self iconForController:controller active:YES];
    button.target = self;
    button.action = @selector(tabBarClicked:);
    button.autoresizingMask = NSViewMinYMargin;
    button.refusesFirstResponder = YES;
    button.keyEquivalentModifierMask = NSCommandKeyMask;
    button.keyEquivalent = [NSString stringWithFormat:@"%ld", position + 1];
    return button;
}

- (void)tabBarClicked:(NSButton *)tabButton {
    NSInteger position = tabButton.tag - SidebarButtonTagStart;
    [self selectControllerAtIndex:position];
}

- (void)unselectCurrentController {
    if (self.selectedTabIndex != SidebarIndexNotSelected) {
        [_barButtons[self.selectedTabIndex] setState:NSOffState];
        self.selectedTabIndex = SidebarIndexNotSelected;
    }
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

- (void)applicationReturnedToForeground {
    if (self.selectedTabIndex != SidebarIndexNotSelected) {
        HIViewController *selectedController = _viewControllers[self.selectedTabIndex];
        [selectedController applicationReturnedToForeground];
    }
}

#pragma mark - badge

- (void)addBadgeForButton:(NSButton *)button controller:(HIViewController *)controller {
    NSButton *badge = [self createBadgeForButton:button];
    [_badges addObject:badge];

    [controller addObserver:self
                 forKeyPath:KEY_BADGE_NUMBER
                    options:NSKeyValueObservingOptionInitial
                    context:&KVO_CONTEXT];
}

- (NSButton *)createBadgeForButton:(NSButton *)button {
    NSButton *badge = [NSButton new];

    badge.bezelStyle = NSRecessedBezelStyle;
    badge.buttonType = NSMomentaryLightButton;
    badge.enabled = NO;

    [self.view addSubview:badge];
    badge.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:@[
        ALIGN_CENTER_X(badge, button, 12),
        ALIGN_CENTER_Y(badge, button, 10),
    ]];

    return badge;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (context == &KVO_CONTEXT) {
        [self updateBadgeForViewController:object];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)updateBadgeForViewController:(HIViewController *)viewController {
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    assert(index != NSNotFound);

    NSUInteger number = viewController.badgeNumber;
    NSButton *badge = _badges[index];
    
    badge.title = [@(number) stringValue];
    badge.hidden = number == 0;
}

- (void)removeBadgeObservers {
    for (NSViewController *viewController in _viewControllers) {
        [viewController removeObserver:self forKeyPath:KEY_BADGE_NUMBER context:&KVO_CONTEXT];
    }
}

@end
