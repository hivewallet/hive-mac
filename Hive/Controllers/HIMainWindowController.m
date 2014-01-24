//
//  HIMainWindowController.m
//  Hive
//
//  Created by Bazyli Zygan on 12.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "HIAppDelegate.h"
#import "HIApplicationsViewController.h"
#import "HIContactsViewController.h"
#import "HIContactViewController.h"
#import "HIMainWindowController.h"
#import "HINavigationController.h"
#import "HIProfile.h"
#import "HIProfileViewController.h"
#import "HISendBitcoinsWindowController.h"
#import "HISidebarController.h"
#import "HITransactionsViewController.h"
#import "HIViewController.h"
#import "NSColor+Hive.h"
#import "NSImage+NPEffects.h"

static const CGFloat TitleBarHeight = 35.0;
static const NSTimeInterval SlideAnimationDuration = 0.3;

@interface HIMainWindowController () {
    NSView *_titleView;
    HIViewController *_currentViewController;
    HIViewController *_currentModalViewController;
}

@property (nonatomic, strong, readonly) INAppStoreWindow *appStoreWindow;

@end

@implementation HIMainWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName {
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
    self.appStoreWindow.titleBarHeight = TitleBarHeight;

    NSArray *panels = @[
                        [HIProfileViewController new],
                        [HIApplicationsViewController new],
                        [HIContactsViewController new],
                        [HITransactionsViewController new],
                      ];

    for (HIViewController *panel in panels) {
        [self.sidebarController addViewController:[[HINavigationController alloc] initWithRootViewController:panel]];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sendWindowDidClose:)
                                                 name:HISendBitcoinsWindowDidClose
                                               object:nil];

    // After everything is set up and visible, start pre-loading the other panels for smooth animation.
    [self performSelector:@selector(preloadViews:)
               withObject:panels
               afterDelay:0];
}

- (void)awakeFromNib {
    // quick fix for send button in some languages (e.g. Russian)
    if (self.sendButton.intrinsicContentSize.width > SidebarButtonWidth) {
        self.sendButton.frame = NSInsetRect(self.sendButton.frame, -2.0, 0.0);
        self.sendButton.font = [NSFont boldSystemFontOfSize:11.0];
    }
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

    newController.view.layer.shadowColor = [[NSColor blackColor] hiNativeColor];
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

#pragma mark - Modality methods

- (void)presentModalViewController:(HIViewController *)controller animated:(BOOL)animated {
   
}

- (void)dismissModalViewControllerAnimated:(BOOL)animated {

}

@end
