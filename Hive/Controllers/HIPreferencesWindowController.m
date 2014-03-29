#import "HIBackupCenterWindowController.h"
#import "HIPreferencesWindowController.h"
#import "HIKeyPreferencesViewController.h"

@implementation HIPreferencesWindowController

- (id)init {
    NSArray *viewControllers = @[
        [HIKeyPreferencesViewController new],
        [HIBackupCenterWindowController new],
    ];
    return [self initWithViewControllers:viewControllers
                                   title:NSLocalizedString(@"Preferences", @"title for preferences window")];
}

- (void)selectBackupCenter {
    [self selectControllerAtIndex:1];
}

@end
