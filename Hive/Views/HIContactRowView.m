//
//  HIContactRowView.m
//  Hive
//
//  Created by Bazyli Zygan on 02.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIContactRowView.h"

@interface HIContactRowView () {
    NSGradient *gradient;
    NSGradient *highlightedGradient;
    NSColor *separatorColor;
}

@end

@implementation HIContactRowView

- (void)awakeFromNib {
    gradient = [[NSGradient alloc] initWithStartingColor:RGB(245, 245, 245)
                                             endingColor:[NSColor whiteColor]];
    
    highlightedGradient = [[NSGradient alloc] initWithStartingColor:RGB(42, 140, 244)
                                                        endingColor:RGB(64, 201, 252)];
    
    separatorColor = RGB(192, 192, 192);
}

- (id)init {
    return [self initWithFrame:NSMakeRect(0, 0, 100, 100)];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self awakeFromNib];
    }
    
    return self;
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
    [gradient drawInRect:self.bounds angle:270.0];
    [separatorColor set];
    
    NSBezierPath *line = [NSBezierPath bezierPath];
    line.lineWidth = 0.5;
    [line moveToPoint:NSMakePoint(0, self.bounds.size.height)];
    [line lineToPoint:NSMakePoint(self.bounds.size.width, self.bounds.size.height)];
    [line stroke];
    
}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
    [highlightedGradient drawInRect:self.bounds angle:270.0];
}

@end
