#import "HICameraWindowController.h"

#import <QTKit/QTkit.h>

@interface HICameraWindowController ()<NSWindowDelegate>

@property (nonatomic, strong) IBOutlet QTCaptureView *captureView;

@property (nonatomic, assign) BOOL waiting;
@property (nonatomic, strong) QTCaptureSession *captureSession;

@end

@implementation HICameraWindowController

- (id)init {
    return [self initWithWindowNibName:[self className]];
}

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        NSError *error;
        [self startCapture:&error];
        if (error) {
            [[NSAlert alertWithError:error] runModal];
        }

        _waiting = YES;
    }

    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    self.captureView.captureSession = self.captureSession;
}

- (void)startCapture:(NSError **)error {
    self.captureSession = [QTCaptureSession new];
    QTCaptureDevice *videoDevice = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
    if ([videoDevice open:error]) {
        QTCaptureDeviceInput *deviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:videoDevice];
        if ([self.captureSession addInput:deviceInput error:error]) {
            [self.captureSession startRunning];
            *error = nil;
        }
    }
}

#pragma mark - NSWindowControllerDelegate

- (void)windowWillClose:(NSNotification *)notification {
    [self.captureSession stopRunning];
}

- (void)windowDidChangeOcclusionState:(NSNotification *)notification {
#pragma deploymate push "ignored-api-availability"
    BOOL visible = (self.window.occlusionState & NSWindowOcclusionStateVisible);
#pragma deploymate pop

    if (visible) {
        [self.captureSession startRunning];
    } else if (!visible) {
        [self.captureSession stopRunning];
    }
}

#pragma mark - QTCaptureViewDelegate

- (CIImage *)view:(QTMovieView *)view willDisplayImage:(CIImage *)image {
    self.waiting = NO;
    return [image imageByApplyingTransform:CGAffineTransformMakeScale(-1, 1)];
}

@end
