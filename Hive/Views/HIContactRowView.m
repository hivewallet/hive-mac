//
//  HIContactRowView.m
//  Hive
//
//  Created by Bazyli Zygan on 02.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIContactRowView.h"

@interface HIContactRowView ()

@property (nonatomic) BOOL mouseInside;
@property (strong) NSTrackingArea *trackingArea;
@property (strong) NSColor *highlightColor;
@property (strong) NSColor *hoverColor;

@end

@implementation HIContactRowView

- (void)awakeFromNib {
    self.hoverColor = [NSColor colorWithCalibratedHue:215/360.0 saturation:0.03 brightness:0.98 alpha:1.0];
    self.highlightColor = [NSColor colorWithCalibratedHue:215/360.0 saturation:0.12 brightness:0.98 alpha:1.0];
}

- (instancetype)init {
    return [self initWithFrame:NSMakeRect(0, 0, 100, 100)];
}

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self awakeFromNib];
    }
    
    return self;
}

- (void)setMouseInside:(BOOL)mouseInside {
    if (_mouseInside != mouseInside) {
        _mouseInside = mouseInside;
        [self setNeedsDisplay:YES];
    }
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
    if (self.mouseInside) {
        [self.hoverColor setFill];
        [NSBezierPath fillRect:dirtyRect];
    } else {
        [super drawBackgroundInRect:dirtyRect];
    }
}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
    [self.highlightColor setFill];
    [NSBezierPath fillRect:dirtyRect];
}

- (NSBackgroundStyle)interiorBackgroundStyle {
    return NSBackgroundStyleLight;
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self removeTrackingArea:self.trackingArea];

    self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                     options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                                       owner:self
                                                    userInfo:nil];
    [self addTrackingArea:self.trackingArea];

    NSPoint mouseLocation = [self.window mouseLocationOutsideOfEventStream];
    self.mouseInside = NSPointInRect([self convertPoint:mouseLocation fromView:nil], self.bounds);

    [super updateTrackingAreas];
}

- (void)dealloc {
    [self removeTrackingArea:self.trackingArea];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    [super mouseEntered:theEvent];
    self.mouseInside = YES;
}

- (void)mouseExited:(NSEvent *)theEvent {
    self.mouseInside = NO;
    [super mouseExited:theEvent];
}

@end
