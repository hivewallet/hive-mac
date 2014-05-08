//
//  HITitleView.m
//  Hive
//
//  Created by Bazyli Zygan on 02.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIDraggableButton.h"
#import "HIRightPointingArrowView.h"
#import "HISidebarController.h"
#import "HITitleView.h"

static const CGFloat TitleSlideDuration = 0.3;
static const CGFloat ArrowViewPadding = 5.0;
static const CGFloat ArrowViewWidth = 8.0;
static const CGFloat ArrowViewLeftMargin = 5.0;
static const CGFloat SmallLabelAlpha = 0.5;

static NSString const *ButtonKey = @"button";
static NSString const *TitleKey = @"title";
static NSString const *ConstraintKey = @"constraint";

@interface HITitleView () {
    NSMutableArray *_stack;
}

@property (nonatomic, strong) NSView *arrowView;
@property (nonatomic, strong) NSLayoutConstraint *arrowSpacingConstraint;

@end

@implementation HITitleView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        _stack = [[NSMutableArray alloc] init];
        self.wantsLayer = YES; // for animation
    }
    
    return self;

}

- (void)pushTitle:(NSString *)title {
    BOOL animated = _stack.count > 0;

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        context.duration = TitleSlideDuration;

        if (_stack.count > 0) {
            [self shiftTopViewLeftAnimated:animated];
            [self addArrowViewAnimated:animated];
            if (_stack.count > 1) {
                [self hideLeftView:animated];
            }
        }
        [self addCenteredViewWithTitle:title ?: @"" animated:animated];

    } completionHandler:nil];
}

- (void)shiftTopViewLeftAnimated:(BOOL)animated {

    NSMutableDictionary *stackItem = _stack[_stack.count - 1];
    HIDraggableButton *button = stackItem[ButtonKey];

    [self removeConstraint:stackItem[ConstraintKey]];
    double startX = button.frame.origin.x;
    NSLayoutConstraint *newConstraint = ALIGN_LEFT(button, self, startX, HIGH);
    [self addConstraint:newConstraint];
    (animated ? newConstraint.animator : newConstraint).constant = SidebarButtonWidth;
    stackItem[ConstraintKey] = newConstraint;

    // Make this button shrink sooner than the main title.
    [button setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
                                     forOrientation:NSLayoutConstraintOrientationHorizontal];
    button.draggable = NO;

    [self setStyleForButton:button title:stackItem[TitleKey] small:YES animated:animated];
}

- (void)addArrowViewAnimated:(BOOL)animated {
    [self.arrowView removeFromSuperview];

    NSView *arrowView = self.arrowView ?: [HIRightPointingArrowView new];
    arrowView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:arrowView];
    [self addConstraints:@[
        INSET_TOP(arrowView, ArrowViewPadding),
        INSET_BOTTOM(arrowView, ArrowViewPadding),
        PIN_WIDTH(arrowView, ArrowViewWidth),
    ]];

    if (animated) {
        arrowView.alphaValue = 0;
        arrowView.animator.alphaValue = SmallLabelAlpha;
    } else {
        arrowView.alphaValue = SmallLabelAlpha;
    }

    self.arrowView = arrowView;

    [self positionArrowViewNextToButtonAtIndex:_stack.count - 1];
}

- (void)positionArrowViewNextToButtonAtIndex:(NSUInteger)index {
    [self removeConstraint:self.arrowSpacingConstraint];
    NSMutableDictionary *stackItem = _stack[index];
    NSButton *button = stackItem[ButtonKey];
    self.arrowSpacingConstraint = HSPACE(button, self.arrowView, ArrowViewLeftMargin);
    [self addConstraint:self.arrowSpacingConstraint];
}

- (void)hideLeftView:(BOOL)animated {
    NSMutableDictionary *stackItem = _stack[_stack.count - 2];
    NSButton *button = stackItem[ButtonKey];
    (animated ? button.animator : button).alphaValue = 0.0;
}

- (void)unhideLeftViewAnimated:(BOOL)animated {
    NSMutableDictionary *stackItem = _stack[_stack.count - 2];
    NSButton *button = stackItem[ButtonKey];
    (animated ? button.animator : button).alphaValue = SmallLabelAlpha;
}

- (void)hideArrowViewAnimated:(BOOL)animated {
    self.arrowView.alphaValue = SmallLabelAlpha;
    (animated ? self.arrowView.animator : self.arrowView).alphaValue = 0;
}

- (void)addCenteredViewWithTitle:(NSString *)title animated:(BOOL)animated {

    NSButton *titleButton = [self createButtonWithTitle:title];
    [self addSubview:titleButton];

    [self addConstraints:@[
        INSET_TOP(titleButton, 0.0),
        INSET_BOTTOM(titleButton, 0.0),
        INSET_LEFT(titleButton, GE(SidebarButtonWidth)),
        INSET_RIGHT(titleButton, GE(0.0)),
    ]];

    if (self.arrowView.superview) {
        [self addConstraint:HSPACE(self.arrowView, titleButton, GE(ArrowViewPadding))];
    }

    [_stack addObject:[@{
        TitleKey: title,
        ButtonKey: titleButton,
    } mutableCopy]];

    [self centerTopViewAnimated:NO isOnlyView:_stack.count == 1];

    if (animated) {
        titleButton.alphaValue = 0;
        titleButton.animator.alphaValue = 1;
    }
}

- (NSButton *)createButtonWithTitle:(NSString *)title {
    NSButton *titleButton = [HIDraggableButton new];
    titleButton.layer.borderWidth = 1.0;
    titleButton.wantsLayer = YES;
    titleButton.translatesAutoresizingMaskIntoConstraints = NO;
    titleButton.bordered = NO;
    titleButton.buttonType = NSToggleButton;
    titleButton.target = self;
    titleButton.action = @selector(leftButtonClicked:);
    [self setStyleForButton:titleButton title:title small:NO animated:NO];
    return titleButton;
}

- (CGSize)setStyleForButton:(NSButton *)button title:(NSString *)title small:(BOOL)small animated:(BOOL)animated {
    NSMutableParagraphStyle *truncatingStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    truncatingStyle.lineBreakMode = NSLineBreakByTruncatingTail;

    NSShadow *sh = [NSShadow new];
    sh.shadowColor = [NSColor whiteColor];
    sh.shadowBlurRadius = 1;
    sh.shadowOffset = NSMakeSize(0, -1);

    NSFont *font = small ? [NSFont systemFontOfSize:10] : [NSFont systemFontOfSize:13];
    CGFloat alpha = small ? SmallLabelAlpha : 1.0;

    NSDictionary *attrs = @{
                            NSParagraphStyleAttributeName: truncatingStyle,
                            NSFontAttributeName: font,
                            NSForegroundColorAttributeName: RGB(30, 30, 30),
                            NSShadowAttributeName: sh
                          };


    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrs];

    id target = animated ? button.animator : button;

    [target setAttributedTitle:attributedTitle];
    [target setAlphaValue:alpha];

    NSSize size = [button.title sizeWithAttributes:attrs];
    return size;
}

- (void)centerTopViewAnimated:(BOOL)animated isOnlyView:(BOOL)onlyView {

    NSMutableDictionary *stackItem = _stack[_stack.count - 1];
    HIDraggableButton *button = stackItem[ButtonKey];
    NSString *title = stackItem[TitleKey];

    CGSize newSize = [self setStyleForButton:button title:title small:NO animated:animated];
    CGFloat centerOffset = onlyView ? 0 : SidebarButtonWidth * .5;

    if (animated) {
        // In 10.8+ we could just add new constraint for animation, but for 10.7 we need to animate a constraint.
        double targetX =
            onlyView
                ? (self.bounds.size.width - newSize.width) * .5
                : MAX(0, (self.bounds.size.width - newSize.width) * .5 - centerOffset) + SidebarButtonWidth;

        NSLayoutConstraint *leftConstraint = stackItem[ConstraintKey];
        leftConstraint.animator.constant = targetX;
    } else {
        [self removeConstraint:stackItem[ConstraintKey]];
        stackItem[ConstraintKey] = ALIGN_CENTER_X(button, self, centerOffset);
        [self addConstraint:stackItem[ConstraintKey]];
    }

    // Make this button not shrink (when possible)
    [button setContentCompressionResistancePriority:NSLayoutPriorityDefaultHigh
                                     forOrientation:NSLayoutConstraintOrientationHorizontal];
    button.draggable = YES;
}

- (void)popToTitleAtPosition:(NSInteger)position {
    NSAssert(0 <= position && position < _stack.count, @"Position does not exist");

    for (long i = _stack.count - 1; i > position; i--) {
        [_stack.lastObject[ButtonKey] removeFromSuperview];
        [_stack removeLastObject];
    }
    BOOL isLastView = position == 0;

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        context.duration = TitleSlideDuration;

        if (isLastView) {
            [self hideArrowViewAnimated:YES];
        } else {
            [self unhideLeftViewAnimated:YES];
            [self positionArrowViewNextToButtonAtIndex:_stack.count - 2];
        }

        [self centerTopViewAnimated:YES isOnlyView:isLastView];

    } completionHandler:^{
        [self centerTopViewAnimated:NO isOnlyView:isLastView];
        if (isLastView) {
            [self.arrowView removeFromSuperview];
        }
    }];
}

- (void)leftButtonClicked:(NSButton *)button {
    if (button != _stack.lastObject[ButtonKey]) {
        [self.delegate requestedPop:self];
    }
}

- (void)updateTitleAtPosition:(NSInteger)position toValue:(NSString *)newTitle {
    NSAssert(0 <= position && position < _stack.count, @"Position does not exist");

    NSButton *button = _stack[position][ButtonKey];
    BOOL isCenterButton = position == _stack.count - 1;
    [self setStyleForButton:button title:newTitle small:!isCenterButton animated:NO];
    _stack[position][TitleKey] = button.title;
}

@end
