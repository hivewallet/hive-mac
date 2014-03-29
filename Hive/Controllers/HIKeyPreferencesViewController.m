#import <MASPreferences/MASPreferencesViewController.h>

#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory.h>
#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory+OSX.h>

#import "HIKeyPreferencesViewController.h"

@implementation HIKeyPreferencesViewController : NSViewController

- (id)init {
    return [self initWithNibName:[self className] bundle:nil];
}

#pragma mark - MASPreferencesViewController

- (NSString *)identifier {
    return @"KeyPreferences";
}

- (NSImage *)toolbarItemImage {
    NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory toolbarItemIconFactory];
    factory.colors = @[[NSColor colorWithCalibratedRed:.2 green:.2 blue:.25 alpha:1.0]];
    return [factory createImageForIcon:NIKFontAwesomeIconKeyboardO];
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"Keys", @"Preferences title for keys");
}

@end
