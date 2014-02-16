@class HICameraWindowController;

@protocol HICameraWindowControllerDelegate<NSObject>

- (BOOL)cameraWindowController:(HICameraWindowController *)cameraWindowController
             didScanBarcodeUrl:(NSString *)barcodeUrl;

@end

/*
 Window showing a camera preview that scans for QR codes.
 */
@interface HICameraWindowController : NSWindowController

@property (nonatomic, weak) id<HICameraWindowControllerDelegate> delegate;

+ (HICameraWindowController *)sharedCameraWindowController;

@end
