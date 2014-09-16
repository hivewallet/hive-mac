#import "HIGeneralPreferencesViewController.h"

#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory+OSX.h>

@implementation HIGeneralPreferencesViewController

- (instancetype)init {
    return [self initWithNibName:[self className] bundle:nil];
}

- (void)awakeFromNib {
    if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_8) {
        // this should be turned on in the xib, but it breaks the view on 10.7
        for (NSView *v in self.view.subviews) {
            if ([v isKindOfClass:[NSMatrix class]]) {
                [(NSMatrix *) v setAutorecalculatesCellSize:YES];
                [(NSMatrix *) v setAutoresizesSubviews:YES];
            }
        }
    }
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
