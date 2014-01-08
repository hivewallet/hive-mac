#import "HINotificationService.h"

#import "BCClient.h"
#import "HITransaction.h"

@interface HINotificationService () <NSUserNotificationCenterDelegate, BCTransactionObserver>
@end

@implementation HINotificationService

+ (HINotificationService *)sharedService {
    static HINotificationService *sharedService = nil;
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        sharedService = [[self class] new];
    });

    return sharedService;
}

- (BOOL)notificationsAvailable {
    return NSClassFromString(@"NSUserNotificationCenter") != nil;
}

- (void)setEnabled:(BOOL)enabled {
    enabled = enabled && self.notificationsAvailable;
    if (!_enabled && enabled) {
        [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
        [[BCClient sharedClient] addTransactionObserver:self];
    } else if (_enabled && !enabled) {
        [[BCClient sharedClient] removeTransactionObserver:self];
    }
    _enabled = enabled;
}

- (void)postNotification:(NSString *)notificationText {
    NSUserNotification *notification = [NSUserNotification new];
    notification.title = notificationText;

    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

#pragma mark - NSUserNotificationCenterDelegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification {
    // So we receive notifications even if in the foreground.
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
       didActivateNotification:(NSUserNotification *)notification {

    if (self.onTransactionClicked) {
        self.onTransactionClicked();
    }
}

#pragma mark - BCTransactionObserver

- (void)transactionAdded:(HITransaction *)transaction {
    if (!transaction.read && transaction.direction == HITransactionDirectionIncoming) {
        [self postReceivedNotification];
    }
}

- (void)transactionConfirmed:(HITransaction *)transaction{
    if (!transaction.read && transaction.direction == HITransactionDirectionOutgoing) {
        [self postSendConfirmedNotification];
    }
}

#pragma mark - Notifications

- (void)postReceivedNotification {
    NSString *message = NSLocalizedString(@"You received Bitcoin", @"Notification of incoming transaction");
    [self postNotification:message];
}

- (void)postSendConfirmedNotification {
    NSString *message = NSLocalizedString(@"Transaction confirmed", @"Notification of confirmed send transaction");
    [self postNotification:message];
}

@end
