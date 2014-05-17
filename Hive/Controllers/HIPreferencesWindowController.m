#import "HIPreferencesWindowController.h"
#import "HIKeyPreferencesViewController.h"
#import "HIGeneralPreferencesViewController.h"

@implementation HIPreferencesWindowController

- (instancetype)init {
    NSArray *viewControllers = @[
        [HIGeneralPreferencesViewController new],
        [HIKeyPreferencesViewController new],
    ];
    return [self initWithViewControllers:viewControllers
                                   title:NSLocalizedString(@"Preferences", @"Preferences window title")];
}

@end
