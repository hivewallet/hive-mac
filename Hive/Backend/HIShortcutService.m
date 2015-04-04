#import <MASShortcut/Shortcut.h>

#import "HIShortcutService.h"

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
    return @"GlobalShortcutKeySend";
}

- (NSString *)cameraPreferenceKey {
    return @"GlobalShortcutKeyOpenCamera";
}

#pragma mark - blocks

- (void)setSendBlock:(void (^)())sendBlock {
    _sendBlock = [sendBlock copy];
    [[MASShortcutBinder sharedBinder] bindShortcutWithDefaultsKey:self.sendPreferenceKey
                                                         toAction:self.sendBlock];
}

- (void)setCameraBlock:(void (^)())cameraBlock {
    _cameraBlock = [cameraBlock copy];
    [[MASShortcutBinder sharedBinder] bindShortcutWithDefaultsKey:self.cameraPreferenceKey
                                                         toAction:self.cameraBlock];
}

@end
