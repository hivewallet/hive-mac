//
//  HICopyView.m
//  Hive
//
//  Created by Bazyli Zygan on 23.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HICopyView.h"
#import "NSColor+Hive.h"

@interface HICopyView () {
    NSTextField *_copyLabel;
    NSUInteger _trackTag;
    NSView *_selectionView;
    NSString *_clickToCopyText;
    NSString *_copiedText;
}

@end

@implementation HICopyView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        self.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
        self.autoresizesSubviews = YES;

        _clickToCopyText = NSLocalizedString(@"click to copy", nil);
        _copiedText = NSLocalizedString(@"copied!", nil);

        _selectionView = [[NSView alloc] initWithFrame:self.bounds];
        _selectionView.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
        _selectionView.wantsLayer = YES;
        _selectionView.layer.backgroundColor = [RGB(42, 140, 244) hiNativeColor];
        _selectionView.alphaValue = 0.0;
        [self addSubview:_selectionView];

        NSFont *labelFont = [NSFont fontWithName:@"Helvetica-Bold" size:12];
        NSSize clickTextSize = [_clickToCopyText sizeWithAttributes:@{NSFontAttributeName: labelFont}];
        NSSize copiedTextSize = [_copiedText sizeWithAttributes:@{NSFontAttributeName: labelFont}];
        CGFloat maxWidth = ceil(MAX(clickTextSize.width, copiedTextSize.width)) + 5.0;

        _copyLabel = [[NSTextField alloc] initWithFrame:
                      NSMakeRect(self.frame.size.width - maxWidth - 10, self.frame.size.height - 25, maxWidth, 15)];
        [_copyLabel setBordered:NO];
        _copyLabel.backgroundColor = [NSColor clearColor];
        _copyLabel.font = labelFont;
        _copyLabel.textColor = [NSColor colorWithCalibratedWhite:0 alpha:0.7];
        [_copyLabel setAlignment:NSRightTextAlignment];
        _copyLabel.autoresizingMask = NSViewMinXMargin | NSViewMinYMargin;
        [_copyLabel setSelectable:NO];
        [_copyLabel setEditable:NO];
        _copyLabel.stringValue = _clickToCopyText;
        [_copyLabel setHidden:YES];
        [self addSubview:_copyLabel];

        _trackTag = [self addTrackingRect:self.bounds owner:self userData:NULL assumeInside:YES];
    }
    
    return self;
}

- (void)setFrame:(NSRect)frameRect {
    [self removeTrackingRect:_trackTag];
    [super setFrame:frameRect];
    _trackTag = [self addTrackingRect:self.bounds owner:self userData:NULL assumeInside:YES];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    _copyLabel.stringValue = _clickToCopyText;
    [self addSubview:_copyLabel];
    [_copyLabel setHidden:NO];
    [self displayIfNeeded];
}

- (void)mouseExited:(NSEvent *)theEvent {
    [_copyLabel setHidden:YES];
    [self displayIfNeeded];
}

- (void)mouseUp:(NSEvent *)theEvent {
    // Well, mouse up, copy data to pasteboard
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb clearContents];
    [pb declareTypes:@[NSStringPboardType] owner:nil];
    [pb setString:_contentToCopy forType:NSStringPboardType];

    _copyLabel.stringValue = _copiedText;

    CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [fadeOut setFromValue:@1.0];
    [fadeOut setDuration:0.2];
    [_selectionView.layer addAnimation:fadeOut forKey:@"opacity"];
}

@end
