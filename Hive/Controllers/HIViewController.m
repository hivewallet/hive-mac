//
//  HIViewController.m
//  Hive
//
//  Created by Bazyli Zygan on 12.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIViewController.h"

@implementation HIViewController

- (id)init {
    self = [self initWithNibName:NSStringFromClass([self class]) bundle:nil];

    if (self) {
        self.badgeNumber = 0;
    }

    return self;
}

- (void)loadView
{
    [super loadView];

    self.view.wantsLayer = YES;
}

- (BOOL)hideButtons
{
    return YES;
}

- (void)viewWillAppear
{
    
}

- (void)viewWillDisappear
{
    
}

- (NSView *)rightNavigationView
{
    return nil;
}

- (NSView *)titleBarView
{
    NSRect frame = NSMakeRect(0, 0, 100, 100);
    
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    label.backgroundColor = [NSColor clearColor];
    label.font = [NSFont systemFontOfSize:13];
    label.editable = NO;
    label.bordered = NO;
    label.bezeled = NO;
    label.alignment = NSCenterTextAlignment;
    label.textColor = RGB(30, 30, 30);
    label.autoresizingMask = NSViewWidthSizable;
    if (self.title)
        label.stringValue = self.title;
    return label;
}

- (void)viewWasSelectedFromTabBar {}
- (void)viewWasSelectedFromTabBarAgain {}

@end
