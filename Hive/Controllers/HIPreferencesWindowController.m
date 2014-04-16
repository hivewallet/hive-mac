#import "HIPreferencesWindowController.h"
#import "HIKeyPreferencesViewController.h"

@implementation HIPreferencesWindowController

- (id)init {
    NSArray *viewControllers = @[
        [HIKeyPreferencesViewController new],
    ];
    return [self initWithViewControllers:viewControllers
                                   title:NSLocalizedString(@"Preferences", @"Preferences window title")];
}

@end
