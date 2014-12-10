#import "HIGeneralPreferencesViewController.h"
#import "HIKeyPreferencesViewController.h"
#import "HIPreferencesWindowController.h"

@implementation HIPreferencesWindowController

- (instancetype)init {
    NSArray *viewControllers = @[
        [HIGeneralPreferencesViewController new],
        [HIKeyPreferencesViewController new],
    ];

    return [self initWithViewControllers:viewControllers
                                   title:NSLocalizedString(@"Preferences", @"Preferences window title")];
}

- (void)awakeFromNib {
    [self.window setShowsResizeIndicator:NO];
}

@end
