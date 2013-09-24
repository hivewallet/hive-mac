//
//  HICopyView.m
//  Hive
//
//  Created by Bazyli Zygan on 23.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "HICopyView.h"
#import "NSColor+NativeColor.h"

@interface HICopyView ()
{
    NSTextField *_copyLabel;
    NSUInteger   _trackTag;
    NSView      *_selectionView;
}

@end

@implementation HICopyView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
//        self.wantsLayer = YES;
//        self.layer.backgroundColor = [[NSColor clearColor] NativeColor];
        self.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
        
        _selectionView = [[NSView alloc] initWithFrame:self.bounds];
        _selectionView.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
        _selectionView.wantsLayer = YES;
        _selectionView.layer.backgroundColor = [RGB(42, 140, 244) NativeColor];
        _selectionView.alphaValue = 0.0;
        [self addSubview:_selectionView];
        _copyLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(self.frame.size.width - 120, self.frame.size.height - 25, 100, 15)];
        [_copyLabel setBordered:NO];
        _copyLabel.backgroundColor = [NSColor clearColor];
        _copyLabel.font = [NSFont fontWithName:@"Helvetica-Bold" size:12];
        _copyLabel.textColor = [NSColor colorWithCalibratedWhite:0 alpha:0.7];
        [_copyLabel setAlignment:NSRightTextAlignment];
        _copyLabel.autoresizingMask = NSViewMinXMargin | NSViewMinYMargin;
        [_copyLabel setSelectable:NO];
        [_copyLabel setEditable:NO];
        self.autoresizesSubviews = YES;
        _copyLabel.stringValue = NSLocalizedString(@"click to copy", nil);
        [_copyLabel setHidden:YES];
        [self addSubview:_copyLabel];
        _trackTag = [self addTrackingRect:self.bounds owner:self userData:NULL assumeInside:YES];
    }
    
    return self;
}

- (void)setFrame:(NSRect)frameRect
{
    [self removeTrackingRect:_trackTag];
    [super setFrame:frameRect];
    _trackTag = [self addTrackingRect:self.bounds owner:self userData:NULL assumeInside:YES];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    _copyLabel.stringValue = NSLocalizedString(@"click to copy", nil);    
    [self addSubview:_copyLabel];
    [_copyLabel setHidden:NO];
    [self displayIfNeeded];
}


- (void)mouseExited:(NSEvent *)theEvent {
    [_copyLabel setHidden:YES];
    [self displayIfNeeded];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    // Well, mouse up, copy data to pasteboard
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb clearContents];
    [pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pb setString:_contentToCopy forType:NSStringPboardType];
    _copyLabel.stringValue = NSLocalizedString(@"copied!", nil);
    _selectionView.alphaValue = 1.0;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_selectionView.animator setAlphaValue:0.0];        
    });

    
}

@end
