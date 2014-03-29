#import "HIShortcutService.h"

#import "MASShortcut+UserDefaults.h"

@implementation HIShortcutService

+ (HIShortcutService *)sharedService {
    static HIShortcutService *sharedService = nil;
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        sharedService = [[self class] new];
    });

    return sharedService;
}

#pragma mark - keys

- (NSString *)sendPreferenceKey {
    return @"key.send";
}

- (NSString *)cameraPreferenceKey {
    return @"key.camera";
}

#pragma mark - blocks

- (void)setSendBlock:(void (^)())sendBlock {
    _sendBlock = [sendBlock copy];
    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:self.sendPreferenceKey
                                                   handler:sendBlock];
}

- (void)setCameraBlock:(void (^)())cameraBlock {
    _cameraBlock = [cameraBlock copy];
    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:self.cameraPreferenceKey
                                                   handler:cameraBlock];
}

@end
