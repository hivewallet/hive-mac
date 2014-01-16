#import "HINotificationService.h"

#import "BCClient.h"
#import "HIBackupAdapter.h"
#import "HIBackupManager.h"
#import "HIBitcoinFormatService.h"
#import "HITransaction.h"

static int KVO_CONTEXT;
static NSString *const HINotificationTypeKey = @"HINotificationTypeKey";

typedef NS_ENUM(NSInteger, HINotificationType) {
    HINotificationTypeTransaction,
    HINotificationTypeBackup,
};

@interface HINotificationService () <NSUserNotificationCenterDelegate, BCTransactionObserver>
@end

@implementation HINotificationService

#pragma deploymate push "ignored-api-availability"

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
        [self postReceivedNotification:transaction];
    }
}

- (void)transactionChangedStatus:(HITransaction *)tx {
    if (tx.direction == HITransactionDirectionOutgoing && tx.status == HITransactionStatusBuilding) {
        [self postSendConfirmedNotification:tx];
    } else if (tx.status == HITransactionStatusDead) {
        [self showCancelledTransactionAlertForTransaction:tx];
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
            [self postBackupErrorNotification:adapter.error];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - Notifications

- (void)postReceivedNotification:(HITransaction *)transaction {
    NSString *btc = [[HIBitcoinFormatService sharedService] stringWithDesignatorForBitcoin:transaction.absoluteAmount];

    [self postNotification:NSLocalizedString(@"You've received Bitcoin", @"Notification of incoming transaction")
                      text:btc
          notificationType:HINotificationTypeTransaction];
}

- (void)postSendConfirmedNotification:(HITransaction *)transaction {
    NSString *btc = [[HIBitcoinFormatService sharedService] stringWithDesignatorForBitcoin:transaction.absoluteAmount];
    NSString *text = [NSString stringWithFormat:
                      NSLocalizedString(@"You have sent %@.",
                                        @"Notification of confirmed sent transaction (with BTC amount)"),
                      btc];

    [self postNotification:NSLocalizedString(@"Transaction completed", @"Notification of confirmed sent transaction")
                      text:text
          notificationType:HINotificationTypeTransaction];
}

- (void)postBackupErrorNotification:(NSError *)error {
    [self postNotification:NSLocalizedString(@"Backup failed", @"Notification of failed backup")
                      text:error.localizedFailureReason
          notificationType:HINotificationTypeBackup];
}

- (void)showCancelledTransactionAlertForTransaction:(HITransaction *)transaction {
    // this should never happen, and if it happens then something went seriously wrong,
    // so let's make sure the user sees this

    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"LLL d jj:mm a"
                                                           options:0
                                                            locale:[NSLocale  currentLocale]];

    NSString *formattedDate = [formatter stringFromDate:transaction.date];

    NSString *title = NSLocalizedString(@"Transaction from %@ was cancelled.",
                                        @"Alert when transaction was cancelled (with transaction date)");

    NSString *message = NSLocalizedString(@"This can happen because of bugs in the wallet code "
                                          @"or because the transaction was rejected by the network.",
                                          @"Alert details when transaction was cancelled");

    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:title, formattedDate]
                                     defaultButton:NSLocalizedString(@"OK", @"OK button title")
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"%@", message];

    [alert setAlertStyle:NSCriticalAlertStyle];

    dispatch_async(dispatch_get_main_queue(), ^{
        [alert runModal];
    });
}

#pragma deploymate pop

@end
