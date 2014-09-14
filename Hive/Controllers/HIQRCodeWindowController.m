//
//  HIQRCodeWindowController.m
//  Hive
//
//  Created by Nikolaj Schumacher on 2014-02-09.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HIQRCodeWindowController.h"

#import "NSColor+Hive.h"

#import <ZXingObjC/ZXingObjC.h>

static const NSTimeInterval CURSOR_HIDE_IDLE_DELAY = 1.0;


@interface HIQRCodeWindowController () <NSWindowDelegate>

@property (nonatomic, weak) IBOutlet NSImageView *imageView;

@property (nonatomic, strong) NSTrackingArea *trackingArea;
@property (nonatomic, strong) NSTimer *mouseIdleTimer;

@end

@implementation HIQRCodeWindowController

- (instancetype)init {
    return [self initWithWindowNibName:[self className]];
}

- (instancetype)initWithWindow:(NSWindow *)window {
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

#pragma mark - QR

+ (dispatch_queue_t)dispatchQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.hivewallet.HIQRCodeWindowController", DISPATCH_QUEUE_SERIAL);
    });

    return queue;
}

- (void)setQRCodeString:(NSString *)QRCodeString {
    _QRCodeString = [QRCodeString copy];
    [self updateQRCode];
}

- (void)updateQRCode {
    if ([self isWindowLoaded] && self.QRCodeString.length) {
        dispatch_async([[self class] dispatchQueue], ^{
            ZXMultiFormatWriter *writer = [ZXMultiFormatWriter writer];
            CGSize size = self.imageView.bounds.size;
            NSError *error = nil;
            ZXBitMatrix *result = [writer encode:self.QRCodeString
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
    [self updateQRCode];

    [self.window.contentView removeTrackingArea: self.trackingArea];
    self.trackingArea = [[NSTrackingArea alloc] initWithRect:[self.window.contentView bounds]
                                                     options:NSTrackingMouseEnteredAndExited
                                                         | NSTrackingActiveAlways | NSTrackingMouseMoved
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
