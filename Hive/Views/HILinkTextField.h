/*
 * Displays a blue underlined link that can be clicked.
 */

typedef NS_ENUM(NSUInteger, HILinkTextFieldUnderlineStyle) {
    HILinkTextFieldUnderlineStyleNone,     // don't underline
    HILinkTextFieldUnderlineStyleAll,      // underline entire string
    HILinkTextFieldUnderlineStyleUsername  // underline from the second character
};

@interface HILinkTextField : NSTextField

@property (nonatomic, copy) IBInspectable NSString *href;
@property (nonatomic, strong) IBInspectable NSColor *linkColor;
@property (nonatomic) HILinkTextFieldUnderlineStyle underlineStyle;

@end
