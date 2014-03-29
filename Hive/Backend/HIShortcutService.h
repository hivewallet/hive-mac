@interface HIShortcutService : NSObject

@property (nonatomic, copy, readonly) NSString *sendPreferenceKey;
@property (nonatomic, copy, readonly) NSString *cameraPreferenceKey;

@property (nonatomic, copy) void (^sendBlock)();
@property (nonatomic, copy) void (^cameraBlock)();

+ (HIShortcutService *)sharedService;

@end
