#import "HINotificationService.h"

#import "BCClient.h"
#import "HIBackupAdapter.h"
#import "HIBackupManager.h"
#import "HIBitcoinFormatService.h"
#import "HITransaction.h"

static int KVO_CONTEXT;
static NSString *const HINotificationTypeKey = @"HINotificationTypeKey";

typedef enum HINotificationType {
    HINotificationTypeTransaction,
    HINotificationTypeBackup,
} HINotificationType;

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
        [self enable];
    } else if (_enabled && !enabled) {
        [self disable];
    }
    _enabled = enabled;
}

- (void)enable {
    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
    [[BCClient sharedClient] addTransactionObserver:self];
    for (HIBackupAdapter *adapter in [HIBackupManager sharedManager].adapters) {
        [adapter addObserver:self forKeyPath:@"error" options:0 context:&KVO_CONTEXT];
    }
}

- (void)disable {
    [[BCClient sharedClient] removeTransactionObserver:self];
    for (HIBackupAdapter *adapter in [HIBackupManager sharedManager].adapters) {
        [adapter removeObserver:self forKeyPath:@"error" context:&KVO_CONTEXT];
    }
}

- (void)postNotification:(NSString *)notificationText
                    text:(NSString *)text
        notificationType:(HINotificationType)notificationType {

    NSUserNotification *notification = [NSUserNotification new];
    notification.title = notificationText;
    notification.informativeText = text;
    notification.userInfo = @{
        HINotificationTypeKey: @(notificationType),
    };

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

    switch ([notification.userInfo[HINotificationTypeKey] longValue]) {
        case HINotificationTypeTransaction:
            if (self.onTransactionClicked) {
                self.onTransactionClicked();
            }
            break;
        case HINotificationTypeBackup:
            if (self.onBackupErrorClicked) {
                self.onBackupErrorClicked();
            }
            break;
    }
}

#pragma mark - BCTransactionObserver

- (void)transactionAdded:(HITransaction *)transaction {
    if (!transaction.read && transaction.direction == HITransactionDirectionIncoming) {
        [self postReceivedNotification:transaction.amount];
    }
}

- (void)transactionConfirmed:(HITransaction *)transaction{
    if (!transaction.read && transaction.direction == HITransactionDirectionOutgoing) {
        [self postSendConfirmedNotification];
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    if (context == &KVO_CONTEXT) {
        HIBackupAdapter *adapter = object;
        if (adapter.error) {
            [self postBackupErrorNotification];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - Notifications

- (void)postReceivedNotification:(satoshi_t)satoshi {
    NSString *message = NSLocalizedString(@"You received Bitcoin", @"Notification of incoming transaction");
    NSString *text = [[HIBitcoinFormatService sharedService] stringWithDesignatorForBitcoin:satoshi];
    [self postNotification:message text:text notificationType:HINotificationTypeTransaction];
}

- (void)postSendConfirmedNotification {
    NSString *message = NSLocalizedString(@"Transaction confirmed", @"Notification of confirmed send transaction");
    [self postNotification:message text:nil notificationType:HINotificationTypeTransaction];
}

- (void)postBackupErrorNotification {
    NSString *message = NSLocalizedString(@"Backup failed", @"Notification of failed backup");
    [self postNotification:message text:nil notificationType:HINotificationTypeBackup];
}

@end
