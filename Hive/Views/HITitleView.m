//
//  HITitleView.m
//  Hive
//
//  Created by Bazyli Zygan on 02.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HISidebarController.h"
#import "HITitleArrowView.h"
#import "HITitleView.h"

static const CGFloat ArrowViewPadding = 5.0;
static const CGFloat ArrowViewWidth = 8.0;
static const CGFloat ArrowViewLeftMargin = 5.0;
static const CGFloat SmallLabelAlpha = 0.5;
static const NSInteger MaxTitleLength = 15;

static NSString * const ButtonKey = @"button";
static NSString * const TitleKey = @"title";

@interface HITitleView ()
{
    NSMutableArray *_stack;
    NSView *_arrowView;
}

@end

@implementation HITitleView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        _stack = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)pushTitle:(NSString *)title
{
    if (!title)
    {
        title = @"";
    }

    NSButton *btn = [[NSButton alloc] init];
    [btn setBordered:NO];
    [btn setButtonType:NSToggleButton];
    [btn setTarget:self];
    [btn setAction:@selector(buttonClicked:)];
    [btn setTitle:title];
    [btn setAutoresizingMask:(NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin)];

    NSSize centerLabelSize = [self setStyleForButton:btn title:title small:NO animated:NO];

    btn.frame = NSMakeRect((self.bounds.size.width - centerLabelSize.width) / 2.0,
                           (self.bounds.size.height - centerLabelSize.height) / 2.0,
                           centerLabelSize.width, centerLabelSize.height);

    if (_stack.count == 0)
    {
        [self addSubview:btn];
        [_stack addObject:@{TitleKey: title, ButtonKey: btn}];
    }
    else
    {
        NSRect frame = btn.frame;
        frame.origin.x = self.bounds.size.width;
        btn.frame = frame;
        [self addSubview:btn];

        NSButton *prevToLast = nil;
        
        if (_stack.count > 1)
        {
            prevToLast = _stack[_stack.count-2][ButtonKey];
        }
        
        NSButton *lastButton = _stack.lastObject[ButtonKey];
        NSString *lastTitle = _stack.lastObject[TitleKey];

        _arrowView = [self arrowView];
        frame = _arrowView.frame;
        frame.origin.x = self.bounds.size.width / 2.0 + lastButton.frame.size.width / 2.0 + ArrowViewLeftMargin;
        _arrowView.frame = frame;
        _arrowView.alphaValue = 0.0;
        [self addSubview:_arrowView];

        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            if (prevToLast)
            {
                [[prevToLast animator] setAlphaValue:0];
            }

            NSSize leftLabelSize = [self setStyleForButton:lastButton title:lastTitle small:YES animated:YES];

            NSRect f = lastButton.frame;
            f.origin.x = SidebarButtonWidth;
            f.origin.y -= 1;
            f.size.width = leftLabelSize.width;
            [lastButton.animator setFrame:f];

            lastButton.autoresizingMask = NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin;

            f = _arrowView.frame;
            f.origin.x = SidebarButtonWidth + leftLabelSize.width + ArrowViewLeftMargin;
            [_arrowView.animator setFrame:f];
            [_arrowView.animator setAlphaValue:SmallLabelAlpha];

            f = btn.frame;
            f.origin.x = (self.bounds.size.width - f.size.width + SidebarButtonWidth) / 2.0;
            [[btn animator] setFrame:f];
        } completionHandler:^{
            [_stack addObject:@{TitleKey: title, ButtonKey: btn}];

            [prevToLast setHidden:YES];

            // just in case the title was changed in the meantime
            [self resizeButtonAtPosition:(_stack.count - 1)];
            [self resizeButtonAtPosition:(_stack.count - 2)];
        }];
    }
}

- (NSSize)setStyleForButton:(NSButton *)button title:(NSString *)title small:(BOOL)small animated:(BOOL)animated
{
    NSMutableParagraphStyle *centredStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [centredStyle setAlignment:NSCenterTextAlignment];

    NSShadow *sh = [NSShadow new];
    sh.shadowColor = [NSColor whiteColor];
    sh.shadowBlurRadius = 1;
    sh.shadowOffset = NSMakeSize(0, -1);

    NSFont *font = small ? [NSFont systemFontOfSize:10] : [NSFont systemFontOfSize:13];
    CGFloat alpha = small ? SmallLabelAlpha : 1.0;

    NSDictionary *attrs = @{
                            NSParagraphStyleAttributeName: centredStyle,
                            NSFontAttributeName: font,
                            NSForegroundColorAttributeName: RGB(30, 30, 30),
                            NSShadowAttributeName: sh
                          };

    NSString *shortTitle = small ? [self truncateTitleIfTooLong:title] : title;
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:shortTitle attributes:attrs];

    id target = animated ? button.animator : button;

    [target setAttributedTitle:attributedTitle];
    [target setAlphaValue:alpha];

    NSSize size = [button.title sizeWithAttributes:attrs];
    size.width += 10;
    return size;
}

- (void)popToTitleAtPosition:(NSInteger)position
{
    NSInteger next = position + 1;
    NSInteger last = _stack.count - 1;

    if (position < 0 || position >= last)
    {
        return;
    }

    NSButton *targetButton = _stack[position][ButtonKey];
    NSButton *previousButton = _stack[last][ButtonKey];
    NSButton *beforePreviousButton = (position > 0) ? _stack[position-1][ButtonKey] : nil;

    NSString *targetButtonTitle = _stack[position][TitleKey];

    for (NSInteger i = next; i < last; i++)
    {
        [_stack[i][ButtonKey] removeFromSuperview];
    }

    [_stack removeObjectsInRange:NSMakeRange(next, last - next)];

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        NSSize s = [self setStyleForButton:targetButton title:targetButtonTitle small:NO animated:YES];

        NSRect f = targetButton.frame;
        f.size.width = s.width;
        f.origin.y += 1;

        if (position == 0)
        {
            f.origin.x = (self.bounds.size.width - f.size.width) / 2.0;
        }
        else
        {
            f.origin.x = (self.bounds.size.width - f.size.width + SidebarButtonWidth) / 2.0;
        }

        [targetButton.animator setFrame:f];

        targetButton.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin;

        f = _arrowView.frame;
        f.origin.x = self.bounds.size.width / 2.0 + s.width / 2.0 + ArrowViewLeftMargin;
        [_arrowView.animator setFrame:f];
        
        if (position == 0)
        {
            [_arrowView.animator setAlphaValue:0.0];
        }
        else
        {
            [beforePreviousButton setHidden:NO];
            [beforePreviousButton.animator setAlphaValue:SmallLabelAlpha];
            [targetButton.animator setAlphaValue:1.0];
        }

        f = previousButton.frame;
        f.origin.x = self.bounds.size.width;
        [previousButton.animator setFrame:f];
    } completionHandler:^{
        [previousButton removeFromSuperview];

        [_stack removeLastObject];
        
        if (position == 0)
        {
            [_arrowView removeFromSuperview];
            _arrowView = nil;
        }
        else
        {
            NSRect f = _arrowView.frame;
            f.origin.x = SidebarButtonWidth + beforePreviousButton.frame.size.width + ArrowViewLeftMargin;
            [_arrowView setFrame:f];
        }

        // just in case the title was changed in the meantime
        [self resizeButtonAtPosition:position];
        [self resizeButtonAtPosition:(position - 1)];
    }];
}

- (NSView *)arrowView
{
    if (_arrowView)
    {
        return _arrowView;
    }
    
    NSRect frame = NSMakeRect(0, ArrowViewPadding,
                              ArrowViewWidth, self.bounds.size.height - 2 * ArrowViewPadding);

    return [[HITitleArrowView alloc] initWithFrame:frame];
}

- (NSString *)truncateTitleIfTooLong:(NSString *)title
{
    if (title.length > MaxTitleLength)
    {
        title = [[title substringToIndex:(MaxTitleLength - 1)] stringByAppendingString:@"…"];
    }

    return title;
}

- (void)buttonClicked:(NSButton *)button
{
    if (button != _stack.lastObject[ButtonKey])
    {
        [self.delegate requestedPop:self];
    }
}

- (void)resizeButtonAtPosition:(NSInteger)position
{
    if (position < 0 || position >= _stack.count)
    {
        return;
    }

    NSButton *button = _stack[position][ButtonKey];
    NSString *title = _stack[position][TitleKey];

    NSRect frame;
    NSSize buttonSize;

    if (position == _stack.count - 2)
    {
        buttonSize = [self setStyleForButton:button title:title small:YES animated:NO];

        frame = button.frame;
        frame.size.width = buttonSize.width;
        button.frame = frame;
    }
    else if (position == _stack.count - 1)
    {
        buttonSize = [self setStyleForButton:button title:title small:NO animated:NO];

        frame = button.frame;
        frame.size.width = buttonSize.width;

        if (position == 0)
        {
            frame.origin.x = (self.bounds.size.width - frame.size.width) / 2.0;
        }
        else
        {
            frame.origin.x = (self.bounds.size.width - frame.size.width + SidebarButtonWidth) / 2.0;
        }

        button.frame = frame;
    }
}

- (void)updateTitleAtPosition:(NSInteger)position toValue:(NSString *)newTitle
{
    if (position < 0 || position >= _stack.count)
    {
        return;
    }

    NSButton *button = _stack[position][ButtonKey];
    _stack[position] = @{TitleKey: newTitle, ButtonKey: button};

    [self resizeButtonAtPosition:position];
}

@end
