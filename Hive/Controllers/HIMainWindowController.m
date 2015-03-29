//
//  HIMainWindowController.m
//  Hive
//
//  Created by Bazyli Zygan on 12.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIContactsViewController.h"
#import "HILockScreenViewController.h"
#import "HIMainWindowController.h"
#import "HINavigationController.h"
#import "HINetworkConnectionMonitor.h"
#import "HIProfileViewController.h"
#import "HISendBitcoinsWindowController.h"
#import "HISidebarController.h"
#import "HITransactionsViewController.h"
#import "HIViewController.h"
#import "NSColor+Hive.h"

static const CGFloat TitleBarHeight = 35.0;
static const NSTimeInterval SlideAnimationDuration = 0.3;


@interface HIMainWindowController () {
    NSView *_titleView;
    HIViewController *_currentViewController;
    NSArray *_tabPanels;
}

// top-level objects
@property (nonatomic, strong) IBOutlet HILockScreenViewController *lockScreenController;
@property (nonatomic, strong) IBOutlet HISidebarController *sidebarController;
@property (nonatomic, strong) IBOutlet NSView *networkErrorView;

@property (nonatomic, weak) IBOutlet NSView *contentView;
@property (nonatomic, weak) IBOutlet NSButton *sendButton;

@property (nonatomic, strong, readonly) INAppStoreWindow *appStoreWindow;

@end


@implementation HIMainWindowController

- (instancetype)initWithWindowNibName:(NSString *)windowNibName {
    return [super initWithWindowNibName:windowNibName];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (INAppStoreWindow *)appStoreWindow {
    return (INAppStoreWindow *)self.window;
}

- (void)windowDidLoad {
    [super windowDidLoad];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center addObserver:self
               selector:@selector(sendWindowDidClose:)
                   name:HISendBitcoinsWindowDidClose
                 object:nil];

    [center addObserver:self
               selector:@selector(onNetworkConnected)
                   name:HINetworkConnectionMonitorConnected
                 object:nil];

    [center addObserver:self
               selector:@selector(onNetworkDisconnected)
                   name:HINetworkConnectionMonitorDisconnected
                 object:nil];

    [center addObserver:self
               selector:@selector(onLockScreenWillAppear)
                   name:LockScreenWillAppearNotification
                 object:nil];

    [center addObserver:self
               selector:@selector(onLockScreenDidAppear)
                   name:LockScreenDidAppearNotification
                 object:nil];

    [center addObserver:self
               selector:@selector(onLockScreenWillDisappear)
                   name:LockScreenWillDisappearNotification
                 object:nil];

    [self.lockScreenController loadView];

    // After everything is set up and visible, start pre-loading the other panels for smooth animation.
    [self performSelector:@selector(preloadViews:)
               withObject:_tabPanels
               afterDelay:0];
}

- (void)awakeFromNib {
    self.appStoreWindow.titleBarHeight = TitleBarHeight;

    _tabPanels = @[
                   [HIProfileViewController new],
                   [HIContactsViewController new],
                   [HITransactionsViewController new],
                 ];

    for (HIViewController *panel in _tabPanels) {
        [self.sidebarController addViewController:[[HINavigationController alloc] initWithRootViewController:panel]];
    }

    // quick fix for send button in some languages (e.g. Russian)
    if (self.sendButton.intrinsicContentSize.width > self.sendButton.frame.size.width) {
        self.sendButton.frame = NSInsetRect(self.sendButton.frame, -2.0, 0.0);
        self.sendButton.font = [NSFont boldSystemFontOfSize:11.0];
    }
}

- (void)onLockScreenWillAppear {
    // set overlay to cover the whole right part of the window
    self.lockScreenController.view.frame = self.contentView.frame;

    [_titleView removeFromSuperview];
    _titleView = nil;

    [self.sidebarController setEnabled:NO];
    [self.sidebarController unselectCurrentController];
}

- (void)onLockScreenDidAppear {
    // without this, the slide in animation doesn't work properly for some reason
    NSRect frame = _currentViewController.view.frame;
    frame.origin.x = 0 - frame.size.width / 3.0;
    [_currentViewController.view setFrame:frame];

    [_currentViewController.view removeFromSuperview];
    _currentViewController = nil;
}

- (void)onLockScreenWillDisappear {
    [self.sidebarController setEnabled:YES];
    [self.sidebarController selectControllerAtIndex:0];
}

- (void)preloadViews:(NSArray *)panels {
    for (NSViewController *panel in panels) {
        if (!panel.view.superview) {
            panel.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
            panel.view.frame = _contentView.bounds;
            [self.contentView addSubview:panel.view
                              positioned:NSWindowBelow
                              relativeTo:_contentView.subviews.lastObject];
            [panel.view removeFromSuperview];
        }
    }
}

- (IBAction)showWindow:(id)sender {
    [super showWindow:sender];
    [self.sidebarController applicationReturnedToForeground];
}

- (void)sendWindowDidClose:(NSNotification *)notification {
    BOOL success = [notification.userInfo[HISendBitcoinsWindowSuccessKey] boolValue];

    if (success) {
        [self.window orderFront:self];
    }
}

- (void)sidebarDidSelectController:(HIViewController *)selectedController again:(BOOL)again {
    if (again) {
        [selectedController viewWasSelectedFromTabBarAgain];
        return;
    }

    HIViewController *prevViewController = _currentViewController;
    _currentViewController = selectedController;

    selectedController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    selectedController.view.frame = _contentView.bounds;

    [selectedController viewWasSelectedFromTabBar];

    if (prevViewController) {
        [self slideControllerIntoView:selectedController slideOut:prevViewController];
    } else {
        _titleView = selectedController.titleBarView;
        NSRect f = _titleView.frame;
        f.size.width = self.appStoreWindow.titleBarView.bounds.size.width;
        f.size.height = self.appStoreWindow.titleBarView.bounds.size.height;
        _titleView.frame = f;
        [self.appStoreWindow.titleBarView addSubview:_titleView];
        [self.contentView addSubview:selectedController.view];
        [selectedController viewWillAppear];
    }
}

- (void)slideControllerIntoView:(HIViewController *)newController slideOut:(HIViewController *)oldController {
    NSRect frame = newController.view.frame;
    frame.origin.x = 0 - frame.size.width;
    newController.view.frame = frame;

    [_contentView addSubview:newController.view];
    [newController viewWillAppear];
    NSView *newTitleView = newController.titleBarView;
    newTitleView.frame = self.appStoreWindow.titleBarView.bounds;
    newTitleView.alphaValue = 0.0;
    [self.appStoreWindow.titleBarView addSubview:newTitleView];

    newController.view.layer.shadowColor = [[NSColor blackColor] CGColor];
    newController.view.layer.shadowOffset = CGSizeMake(50.0, 0.0);
    newController.view.layer.shadowRadius = 50.0;
    newController.view.layer.shadowOpacity = 0.25;

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = SlideAnimationDuration;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

        [[_titleView animator] setAlphaValue:0.0];
        [[newTitleView animator] setAlphaValue:1.0];
    } completionHandler:^{
        [_titleView removeFromSuperview];
        _titleView = newTitleView;
    }];

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = SlideAnimationDuration;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

        NSRect frame = newController.view.frame;
        frame.origin.x = 0;
        [newController.view.animator setFrame:frame];
    } completionHandler:^{
        newController.view.layer.shadowOpacity = 0.0;
    }];

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = SlideAnimationDuration;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];

        NSRect frame = oldController.view.frame;
        frame.origin.x = 0 - frame.size.width / 3.0;
        [oldController.view.animator setFrame:frame];
    } completionHandler:^{
        [oldController.view removeFromSuperview];
    }];
}


#pragma mark - Changing title bar state

- (void)windowDidBecomeKey:(NSNotification *)notification {
    _titleView.alphaValue = 1.0;
}

- (void)windowDidResignKey:(NSNotification *)notification {
    _titleView.alphaValue = 0.6;
    [_currentViewController viewWillDisappear];
}


#pragma mark - Network connection status

- (void)onNetworkConnected {
    if (self.networkErrorView.superview) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = SlideAnimationDuration;
            context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

            CGFloat barHeight = self.networkErrorView.frame.size.height;
            [self expandView:self.contentView.animator by:barHeight];
            [self expandView:self.sidebarController.view.animator by:barHeight];
            [self moveView:self.networkErrorView.animator by:barHeight];
        } completionHandler:^{
            [self.networkErrorView removeFromSuperview];
        }];
    }
}

- (void)onNetworkDisconnected {
    if (!self.networkErrorView.superview) {
        NSView *rootView = self.window.contentView;

        NSRect errorViewFrame = self.networkErrorView.frame;
        errorViewFrame.origin.x = 0;
        errorViewFrame.origin.y = rootView.bounds.size.height;
        errorViewFrame.size.width = rootView.bounds.size.width;
        self.networkErrorView.frame = errorViewFrame;

        [self.window.contentView addSubview:self.networkErrorView];

        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = SlideAnimationDuration;
            context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

            CGFloat barHeight = self.networkErrorView.frame.size.height;
            [self expandView:self.contentView.animator by:-barHeight];
            [self expandView:self.sidebarController.view.animator by:-barHeight];
            [self moveView:self.networkErrorView.animator by:-barHeight];
        } completionHandler:^{}];
    }
}

- (void)expandView:(NSView *)view by:(CGFloat)diff {
    NSRect frame = view.frame;
    frame.size.height += diff;
    view.frame = frame;
}

- (void)moveView:(NSView *)view by:(CGFloat)diff {
    NSRect frame = view.frame;
    frame.origin.y += diff;
    view.frame = frame;
}


#pragma mark - Switching panels

- (void)switchToPanel:(Class)panelClass {
    int index = 0;
    for (HINavigationController *panel in self.sidebarController.viewControllers) {
        if ([panel.rootViewController isKindOfClass:panelClass]) {
            [self.sidebarController selectControllerAtIndex:index];
            break;
        }
        index++;
    }
}

@end
