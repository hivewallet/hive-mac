//
//  HIBarcodeWindowController.m
//  Hive
//
//  Created by Nikolaj Schumacher on 2014-02-09.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HIBarcodeWindowController.h"

#import "NSColor+Hive.h"

#import <ZXingObjC/ZXingObjC.h>

static const NSTimeInterval CURSOR_HIDE_IDLE_DELAY = 1.0;

@interface HIBarcodeWindowController ()<NSWindowDelegate>

@property (nonatomic, strong) IBOutlet NSImageView *imageView;
@property (nonatomic, strong) NSTrackingArea *trackingArea;
@property (nonatomic, strong) NSTimer *mouseIdleTimer;

@end

@implementation HIBarcodeWindowController

- (id)init {
    return [self initWithWindowNibName:[self className]];
}

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        NSPanel *panel = (NSPanel *)self.window;
        panel.floatingPanel = YES;
        panel.hidesOnDeactivate = YES;
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];

    [self.window.contentView setWantsLayer:YES];
    [self.window.contentView layer].backgroundColor = [NSColor whiteColor].hiNativeColor;
}


- (void)dealloc {
    [self.window.contentView removeTrackingArea: self.trackingArea];
}

- (void)setBarcodeString:(NSString *)barcodeString {
    _barcodeString = [barcodeString copy];
    [self updateBarcode];
}

- (void)updateBarcode {
    if ([self isWindowLoaded] && self.barcodeString.length) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            ZXMultiFormatWriter *writer = [ZXMultiFormatWriter writer];
            CGSize size = self.imageView.bounds.size;
            NSError *error = nil;
            ZXBitMatrix *result = [writer encode:self.barcodeString
                                          format:kBarcodeFormatQRCode
                                           width:size.width
                                          height:size.height
                                           error:&error];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (result) {
                    self.imageView.image =
                        [[NSImage alloc] initWithCGImage:[[ZXImage imageWithMatrix:result] cgimage]
                                                    size:NSZeroSize];
                } else {
                    HILogError(@"Creating QR code failed with error: %@", error.localizedDescription);
                    self.imageView.image = nil;
                }
            });
        });
    }
}

#pragma mark - NSWindowDelegate

- (void)windowDidResize:(NSNotification *)notification {
    [self updateBarcode];

    [self.window.contentView removeTrackingArea: self.trackingArea];
    self.trackingArea = [[NSTrackingArea alloc] initWithRect:[self.window.contentView bounds]
                                                     options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                                       owner:self
                                                    userInfo:nil];
    [self.window.contentView addTrackingArea:self.trackingArea];

    [NSCursor setHiddenUntilMouseMoves:YES];
}

- (void)windowWillClose:(NSNotification *)notification {
    [self.mouseIdleTimer invalidate];
    [NSCursor setHiddenUntilMouseMoves:NO];
}

#pragma mark - mouse

- (void)mouseMoved:(NSEvent *)theEvent {
    [super mouseMoved:theEvent];
    [self.mouseIdleTimer invalidate];
    self.mouseIdleTimer = [NSTimer scheduledTimerWithTimeInterval:CURSOR_HIDE_IDLE_DELAY
                                                           target:self
                                                         selector:@selector(hideCursor)
                                                         userInfo:nil
                                                          repeats:NO];
}

- (void)mouseExited:(NSEvent *)theEvent {
    [super mouseExited:theEvent];
    [self.mouseIdleTimer invalidate];
    [self.window close];
}

- (void)mouseDown:(NSEvent *)theEvent {
    [super mouseDown:theEvent];
    [self.window close];
}

- (void)hideCursor {
    [NSCursor setHiddenUntilMouseMoves:YES];
}

@end
