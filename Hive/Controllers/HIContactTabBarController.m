//
//  HIContactTabBarController.m
//  Hive
//
//  Created by Jakub Suder on 06.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIContactTabBarController.h"
#import "NSColor+Hive.h"

static NSInteger TabBarButtonTagStart = 1000;

@interface HIContactTabBarController ()
{
    NSArray *_tabBarButtons;
}

@end

@implementation HIContactTabBarController

- (void)awakeFromNib {
    _tabBarButtons = @[
                       [self tabBarButtonAtPosition:0 iconName:@"user"],
                       [self tabBarButtonAtPosition:1 iconName:@"timeline"]
                     ];

    for (NSButton *button in _tabBarButtons) {
        [self.view addSubview:button];
    };

    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;

    [self.view addSubview:[self horizontalLineAtPosition:(height - 1) color:RGB(212, 212, 212)]];
    [self.view addSubview:[self horizontalLineAtPosition:(height - 2) color:[NSColor whiteColor]]];
    [self.view addSubview:[self horizontalLineAtPosition:1 color:RGB(177, 177, 177)]];

    [self.view addSubview:[self verticalSeparatorAtPosition:(width/2) color:RGB(187, 187, 187)]];
}

- (NSButton *)tabBarButtonAtPosition:(NSInteger)position iconName:(NSString *)name {
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    NSRect frame = NSMakeRect(width / 2 * position, 0, width / 2, height);

    NSButton *button = [[NSButton alloc] initWithFrame:frame];
    button.buttonType = NSToggleButton;
    button.bordered = NO;
    button.state = NSOffState;
    button.tag = TabBarButtonTagStart + position;
    button.image = [NSImage imageNamed:[NSString stringWithFormat:@"icon-tabbar-%@__inactive", name]];
    button.alternateImage = [NSImage imageNamed:[NSString stringWithFormat:@"icon-tabbar-%@__active", name]];
    button.target = self;
    button.action = @selector(tabBarClicked:);

    if (position == 0) {
        button.autoresizingMask = NSViewMaxXMargin | NSViewWidthSizable;
    } else {
        button.autoresizingMask = NSViewMinXMargin | NSViewWidthSizable;
    }

    return button;
}

- (NSView *)horizontalLineAtPosition:(CGFloat)position color:(NSColor *)color {
    NSRect frame = NSMakeRect(0, position, self.view.frame.size.width, 1);
    NSView *line = [[NSView alloc] initWithFrame:frame];
    line.wantsLayer = YES;
    line.layer.backgroundColor = [color hiNativeColor];
    line.autoresizingMask = NSViewMinYMargin | NSViewMaxYMargin | NSViewWidthSizable;
    return line;
}

- (NSView *)verticalSeparatorAtPosition:(CGFloat)position color:(NSColor *)color {
    NSRect frame = NSMakeRect(position, 10, 1, self.view.frame.size.height - 20);
    NSView *line = [[NSView alloc] initWithFrame:frame];
    line.wantsLayer = YES;
    line.layer.backgroundColor = [color hiNativeColor];
    line.layer.shadowColor = [[NSColor whiteColor] hiNativeColor];
    line.layer.shadowOffset = NSMakeSize(1.0, 0.0);
    line.layer.shadowOpacity = 1.0;
    line.layer.shadowRadius = 0.0;
    line.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewHeightSizable;
    return line;
}

- (void)selectTabAtIndex:(NSUInteger)selectedIndex
{
    for (NSInteger i = 0; i < _tabBarButtons.count; i++)
    {
        [_tabBarButtons[i] setState:(i == selectedIndex ? NSOnState : NSOffState)];
    }

    if ([_tabDelegate respondsToSelector:@selector(controller:switchedToTabIndex:)])
    {
        [_tabDelegate controller:self switchedToTabIndex:selectedIndex];
    }
}

- (void)tabBarClicked:(id)sender {
    NSInteger buttonId = [sender tag] - TabBarButtonTagStart;

    [self selectTabAtIndex:buttonId];
}

@end
