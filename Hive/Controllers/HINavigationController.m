//
//  HINavigationController.m
//  Hive
//
//  Created by Jakub Suder on 30.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "HINavigationController.h"
#import "HITitleView.h"

static CGFloat ViewSlideDuration = 0.3;


@interface HINavigationController () {
    NSMutableArray *viewControllers;
    HITitleView *_titleView;
    HIViewController *_rootViewController;
    BOOL _animating;
}

@end

@implementation HINavigationController

- (id)initWithRootViewController:(HIViewController *)rootViewController {
    self = [super init];

    if (self) {
        viewControllers = [[NSMutableArray alloc] init];
        _rootViewController = rootViewController;
    }

    return self;
}

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)];
    self.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.view.autoresizesSubviews = YES;
    [self pushViewController:_rootViewController animated:NO];
}

- (HIViewController *)topViewController {
    return [viewControllers lastObject];
}

- (HIViewController *)rootViewController {
    if (viewControllers.count > 0)
        return viewControllers[0];
    else
        return _rootViewController;
}

- (NSArray *)viewControllers {
    return viewControllers;
}


- (NSString *)title {
    return self.rootViewController.title;
}

- (NSView *)titleBarView
{
    if (!_titleView)
    {
        _titleView = [[HITitleView alloc] initWithFrame:NSMakeRect(0, 0, 200, 40)];
        _titleView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        _titleView.delegate = self;
        [_titleView pushTitle:self.rootViewController.title];
    }
    
    return _titleView;
}

- (NSString *)iconName {
    return self.rootViewController.iconName;
}

- (void)pushViewController:(HIViewController *)controller animated:(BOOL)animated {
    
    if (_animating)
        return;
    controller.view.frame = self.view.bounds;
    controller.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    controller.navigationController = self;

    HIViewController *previous = self.topViewController;
    [previous viewWillDisappear];
    [controller viewWillAppear];
    [viewControllers addObject:controller];
    [_titleView pushTitle:controller.title];
    if (!animated) {
        if (previous.rightNavigationView)
            [previous.rightNavigationView removeFromSuperview];
        
        if (controller.rightNavigationView)
        {
            NSRect f = controller.rightNavigationView.frame;
            f.origin.x = self.titleBarView.frame.size.width - f.size.width - 10;
            controller.rightNavigationView.frame = f;
            controller.rightNavigationView.alphaValue = 1.0;
            controller.rightNavigationView.autoresizingMask = NSViewMinXMargin;
            [self.titleBarView addSubview:controller.rightNavigationView];
        }
        [self.view addSubview:controller.view];
        [controller.view becomeFirstResponder];
        [previous.view removeFromSuperview];            
    } else {
        NSRect frame = controller.view.frame;
        frame.origin.x = frame.size.width;
        controller.view.frame = frame;

        [self.view addSubview:controller.view];
        _animating = YES;

        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = ViewSlideDuration;
            context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

            NSRect frame = controller.view.frame;
            frame.origin.x = 0;
            [controller.view.animator setFrame:frame];

            if (previous) {
                frame = previous.view.frame;
                frame.origin.x = 0 - frame.size.width;
                [previous.view.animator setFrame:frame];
            }
            
            if (previous.rightNavigationView)
                [[previous.rightNavigationView animator] setAlphaValue:0.0];
            
            if (controller.rightNavigationView)
            {
                NSRect f = controller.rightNavigationView.frame;
                f.origin.x = _titleView.frame.size.width - f.size.width - 10;
                controller.rightNavigationView.frame = f;
                controller.rightNavigationView.autoresizingMask = NSViewMinXMargin;
                controller.rightNavigationView.alphaValue = 0.0;
                [_titleView addSubview:controller.rightNavigationView];
                [[controller.rightNavigationView animator] setAlphaValue:1.0];
            }
            
        } completionHandler:^{
            if (previous.rightNavigationView)
                [previous.rightNavigationView removeFromSuperview];
            [controller.view becomeFirstResponder];
            [previous.view removeFromSuperview];
            _animating = NO;
        }];
    }
}

- (void)popToViewController:(HIViewController *)targetController animated:(BOOL)animated {
    
    if (_animating)
        return;
    
    HIViewController *current = self.topViewController;
    NSInteger index = [self.viewControllers indexOfObject:targetController];

    if (targetController == current || index == NSNotFound) {
        return;
    }

    [_titleView popToTitleAtPosition:index];
    [targetController viewWillAppear];
    [self.topViewController viewWillDisappear];
    NSRange afterCurrent = NSMakeRange(index + 1, viewControllers.count - index - 1);
    [viewControllers removeObjectsInRange:afterCurrent];

    targetController.view.frame = self.view.bounds;
    targetController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    if (!animated) {
        if (current.rightNavigationView)
            [current.rightNavigationView removeFromSuperview];
        
        if (targetController.rightNavigationView)
        {
            NSRect f = targetController.rightNavigationView.frame;
            f.origin.x = _titleView.frame.size.width - f.size.width - 10;
            targetController.rightNavigationView.frame = f;
            targetController.rightNavigationView.alphaValue = 1.0;
            targetController.rightNavigationView.autoresizingMask = NSViewMinXMargin;
            [_titleView addSubview:targetController.rightNavigationView];
        }
        [self.view addSubview:targetController.view];
        [targetController.view becomeFirstResponder];
        [current.view removeFromSuperview];
    } else {
        NSRect frame = targetController.view.frame;
        frame.origin.x = 0 - frame.size.width;
        targetController.view.frame = frame;

        [self.view addSubview:targetController.view];
        _animating = YES;
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = ViewSlideDuration;
            context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

            if (current.rightNavigationView)
                [[current.rightNavigationView animator] setAlphaValue:0.0];
            
            if (targetController.rightNavigationView)
            {
                NSRect f = targetController.rightNavigationView.frame;
                f.origin.x = _titleView.frame.size.width - f.size.width - 10;
                targetController.rightNavigationView.frame = f;
                targetController.rightNavigationView.autoresizingMask = NSViewMinXMargin;
                targetController.rightNavigationView.alphaValue = 0.0;
                [_titleView addSubview:targetController.rightNavigationView];
                [[targetController.rightNavigationView animator] setAlphaValue:1.0];
            }
            NSRect frame = targetController.view.frame;
            frame.origin.x = 0;
            [targetController.view.animator setFrame:frame];

            frame = current.view.frame;
            frame.origin.x = frame.size.width;
            [current.view.animator setFrame:frame];
        } completionHandler:^{
            if (current.rightNavigationView)
                [current.rightNavigationView removeFromSuperview];
            [targetController.view becomeFirstResponder];
            [current.view removeFromSuperview];
            _animating = NO;
        }];
    }
}

- (void)requestedPop:(HITitleView *)titleView
{
    [self popViewController:YES];
}

- (void)popViewController:(BOOL)animated {
    if (self.viewControllers.count < 2) {
        return;
    }

    HIViewController *previous = self.viewControllers[self.viewControllers.count - 2];
    [self popToViewController:previous animated:animated];
}

- (void)popToRootViewControllerAnimated:(BOOL)animated {
    if (self.viewControllers.count < 2) {
        return;
    }
    [self popToViewController:self.rootViewController animated:animated];
}

- (void)viewWasSelectedFromTabBar {
    [self popToRootViewControllerAnimated:NO];
}

- (void)viewWasSelectedFromTabBarAgain {
    [self popToRootViewControllerAnimated:YES];
}

@end
