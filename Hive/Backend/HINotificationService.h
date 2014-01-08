@interface HINotificationService : NSObject

@property (nonatomic, assign, readonly) BOOL notificationsAvailable;
@property (nonatomic, assign) BOOL enabled;

@property (nonatomic, copy) void (^onTransactionClicked)();
@property (nonatomic, copy) void (^onBackupErrorClicked)();

+ (HINotificationService *)sharedService;

@end
