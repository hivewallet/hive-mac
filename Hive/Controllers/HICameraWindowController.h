@class QTCaptureSession;

/*
 Window showing a camera preview that scans for QR codes.
 */
@interface HICameraWindowController : NSWindowController

+ (HICameraWindowController *)sharedCameraWindowController;

@end
