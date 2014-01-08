@interface HINotificationService : NSObject

@property (nonatomic, assign, readonly) BOOL notificationsAvailable;
@property (nonatomic, assign) BOOL enabled;

@property (nonatomic, copy) void (^onTransactionClicked)();

+ (HINotificationService *)sharedService;

@end
