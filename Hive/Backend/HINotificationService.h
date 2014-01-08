@interface HINotificationService : NSObject

@property (nonatomic, assign, readonly) BOOL notificationsAvailable;
@property (nonatomic, assign) BOOL enabled;

+ (HINotificationService *)sharedService;

@end
