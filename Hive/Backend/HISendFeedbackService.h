@interface HISendFeedbackService : NSObject


+ (HISendFeedbackService *)sharedService;

- (void)sendSupportEmail;
@end
