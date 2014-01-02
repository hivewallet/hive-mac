//
//  HITransactionCellView.m
//  Hive
//
//  Created by Jakub Suder on 06.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HITransactionCellView.h"

@interface HITransactionCellView ()

@property (nonatomic, assign) BOOL mouseInside;
@property (nonatomic, strong) NSTrackingArea *trackingArea;

@end


@implementation HITransactionCellView

- (IBAction)shareButtonPressed:(NSButton *)sender {
    NSSharingServicePicker *sharingServicePicker = [[NSSharingServicePicker alloc] initWithItems:@[self.shareText]];
    [sharingServicePicker showRelativeToRect:sender.bounds ofView:sender preferredEdge:CGRectMaxXEdge];
}

#pragma mark - mouse handling

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
