//
//  HIButtonWithSpinner.m
//  Hive
//
//  Created by Jakub Suder on 06.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIButtonWithSpinner.h"

CGFloat SpinnerAnimationTime = 0.3;
CGFloat SpinnerSize = 16.0;

@interface HIButtonWithSpinner () {
    NSProgressIndicator *_spinner;
    NSRect _originalBounds;
}

@end

@implementation HIButtonWithSpinner

- (void)showSpinner {
    [self setEnabled:NO];

    _spinner = [self buildSpinner];
    [_spinner startAnimation:self];
    [self addSubview:_spinner];

    _originalBounds = self.bounds;

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = SpinnerAnimationTime;

        NSRect frame = self.frame;
        frame.size.width += SpinnerSize / 2;
        frame.origin.x -= SpinnerSize / 2;
        [self.animator setFrame:frame];
    } completionHandler:^{}];
}

- (NSProgressIndicator *)buildSpinner {
    CGFloat position = (self.bounds.size.height - SpinnerSize) / 2;
    NSRect frame = NSMakeRect(position, position, SpinnerSize, SpinnerSize);

    NSProgressIndicator *spinner = [[NSProgressIndicator alloc] initWithFrame:frame];
    spinner.style = NSProgressIndicatorSpinningStyle;
    spinner.controlSize = NSSmallControlSize;
    return spinner;
}

- (void)hideSpinner {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = SpinnerAnimationTime;

        NSRect frame = self.frame;
        frame.size.width -= SpinnerSize / 2;
        frame.origin.x += SpinnerSize / 2;
        [self.animator setFrame:frame];
    } completionHandler:^{
        [self setEnabled:YES];

        [_spinner removeFromSuperview];
        _spinner = nil;
    }];
}

- (NSRect)titleFrame {
    NSRect frame;

    if (_spinner) {
        frame = _originalBounds;
        frame.origin.x += (self.bounds.size.width - _originalBounds.size.width);
    } else {
        frame = self.bounds;
    }

    return NSMakeRect(frame.origin.x + 12, frame.origin.y + 4, frame.size.width - 24, frame.size.height - 12);
}

@end
