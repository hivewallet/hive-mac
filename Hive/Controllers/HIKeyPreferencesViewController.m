#import <MASPreferences/MASPreferencesViewController.h>

#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory.h>
#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory+OSX.h>

#import "HIKeyPreferencesViewController.h"
#import "MASShortcutView.h"
#import "MASShortcutView+UserDefaults.h"
#import "HIShortcutService.h"

@interface HIKeyPreferencesViewController ()

@property (nonatomic, strong) IBOutlet MASShortcutView *sendShortcutPicker;
@property (nonatomic, strong) IBOutlet MASShortcutView *cameraShortcutPicker;

@end

@implementation HIKeyPreferencesViewController : NSViewController

- (instancetype)init {
    return [self initWithNibName:[self className] bundle:nil];
}

- (void)awakeFromNib {
    HIShortcutService *shortcutService = [HIShortcutService sharedService];
    self.sendShortcutPicker.associatedUserDefaultsKey = shortcutService.sendPreferenceKey;
    self.cameraShortcutPicker.associatedUserDefaultsKey = shortcutService.cameraPreferenceKey;
    [super awakeFromNib];
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
    return NSLocalizedString(@"Shortcuts", @"Title for shortcut keys preferences panel");
}

- (NSView *)initialKeyView {
    return nil;
}

@end
