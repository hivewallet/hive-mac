@class HICameraWindowController;

@protocol HICameraWindowControllerDelegate<NSObject>

- (BOOL)cameraWindowController:(HICameraWindowController *)cameraWindowController
              didScanQRCodeURI:(NSString *)QRCodeURI;

@end

/*
 Window showing a camera preview that scans for QR codes.
 */
@interface HICameraWindowController : NSWindowController

@property (nonatomic, strong) id<HICameraWindowControllerDelegate> delegate;

+ (HICameraWindowController *)sharedCameraWindowController;

@end
