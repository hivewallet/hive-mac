/*
 Service that takes care of sending notifications to the notification center.
 */
@interface HINotificationService : NSObject

/* Test in notifications are supported on the current OS version. */
@property (nonatomic, assign, readonly) BOOL notificationsAvailable;
/* Enables or disables notifications. */
@property (nonatomic, assign) BOOL enabled;

/* Block to execute when the user clicks on a transaction notification. */
@property (nonatomic, copy) void (^onTransactionClicked)();
/* Block to execute when the user clicks on a backup error notification. */
@property (nonatomic, copy) void (^onBackupErrorClicked)();

+ (HINotificationService *)sharedService;

@end
