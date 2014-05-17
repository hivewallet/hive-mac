#import "HIGeneralPreferencesViewController.h"

#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory+OSX.h>

@interface HIGeneralPreferencesViewController ()
@end

@implementation HIGeneralPreferencesViewController

- (instancetype)init {
    return [self initWithNibName:[self className] bundle:nil];
}

#pragma mark - MASPreferencesViewController

- (NSString *)identifier {
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage {
    NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory toolbarItemIconFactory];
    factory.colors = @[[NSColor colorWithCalibratedRed:.2 green:.2 blue:.25 alpha:1.0]];
    return [factory createImageForIcon:NIKFontAwesomeIconCogs];
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"General", @"Title for general preferences panel");
}

@end
