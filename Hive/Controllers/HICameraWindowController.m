#import "HICameraWindowController.h"

#import "HIBitcoinUrlService.h"
#import "ZXLuminanceSource.h"

#import <QTKit/QTkit.h>
#import <ZXingObjC/ZXingObjC.h>

static const NSTimeInterval SCAN_INTERVAL = .25;

@interface HICameraWindowController ()<NSWindowDelegate>

@property (nonatomic, strong) IBOutlet QTCaptureView *captureView;

@property (nonatomic, assign) BOOL waiting;
@property (nonatomic, assign) BOOL scanning;
@property (nonatomic, strong) QTCaptureSession *captureSession;
@property (nonatomic, copy) NSDate *lastScanDate;

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
        _lastScanDate = [NSDate dateWithTimeIntervalSince1970:0];
    }

    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    self.captureView.captureSession = self.captureSession;
}

- (BOOL)startCapture:(NSError **)error {
    self.captureSession = [QTCaptureSession new];
    QTCaptureDevice *videoDevice = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];

    if ([videoDevice open:error]) {
        QTCaptureDeviceInput *deviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:videoDevice];

        if ([self.captureSession addInput:deviceInput error:error]) {
            [self.captureSession startRunning];

            if (error) {
                *error = nil;
            }

            return YES;
        }
    }

    return NO;
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
    } else {
        [self.captureSession stopRunning];
    }
}

#pragma mark - QTCaptureViewDelegate

- (CIImage *)view:(QTMovieView *)view willDisplayImage:(CIImage *)image {
    self.waiting = NO;
    [self processImage:image];
    return [image imageByApplyingTransform:CGAffineTransformMakeScale(-1, 1)];
}

#pragma mark - barcode

- (void)processImage:(CIImage *)image {
    if (!self.scanning && [[NSDate new] timeIntervalSinceDate:self.lastScanDate] > SCAN_INTERVAL) {
        self.lastScanDate = [NSDate new];
        self.scanning = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *scannedBarcode = [self scanBarcodeInImage:image];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (scannedBarcode) {
                    if ([[HIBitcoinUrlService sharedService] handleBitcoinUrlString:scannedBarcode]) {
                        [self.captureSession stopRunning];
                        [self.window performClose:nil];
                    }
                }
                self.scanning = NO;
            });
        });
    }
}

- (NSString *)scanBarcodeInImage:(CIImage *)image {

    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCIImage:image];
    CGImageRef imageToDecode = rep.CGImage;

    ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:imageToDecode];
    ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];

    ZXDecodeHints *hints = [ZXDecodeHints hints];
    [hints addPossibleFormat:kBarcodeFormatQRCode];

    ZXMultiFormatReader *reader = [ZXMultiFormatReader reader];
    ZXResult *result = [reader decode:bitmap
                                hints:hints
                                error:NULL];
    return result.text;
}

@end
