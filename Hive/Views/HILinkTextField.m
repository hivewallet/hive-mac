#import "HILinkTextField.h"

@implementation HILinkTextField

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];

    if (self) {
        [self initialize];
        [self awakeFromNib];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];

    if (self) {
        [self initialize];
    }

    return self;
}

- (void)initialize {
    _linkColor = [NSColor blueColor];
    _underlineStyle = HILinkTextFieldUnderlineStyleAll;
}

- (void)awakeFromNib {
    [self setEditable:NO];
    [self setBordered:NO];
    [self setDrawsBackground:NO];
}

- (void)setStringValue:(NSString *)aString {
    [super setStringValue:aString];
    [self updateLink];
}

- (void)setHref:(NSString *)href {
    _href = [href copy];
    [self updateLink];
}

- (void)setFont:(NSFont *)font {
    [super setFont:font];
    [self updateLink];
}

- (void)setLinkColor:(NSColor *)linkColor {
    if (![_linkColor isEqual:linkColor]) {
        _linkColor = linkColor;
        [self updateLink];
    }
}

- (void)setUnderlineStyle:(HILinkTextFieldUnderlineStyle)underlineStyle {
    if (_underlineStyle != underlineStyle) {
        _underlineStyle = underlineStyle;
        [self updateLink];
    }
}

- (void)updateLink {
    if (!_href) {
        return;
    }

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:self.stringValue];
    NSRange range = NSMakeRange(0, string.length);
    [string addAttribute:NSLinkAttributeName value:_href range:range];
    [string addAttribute:NSForegroundColorAttributeName value:self.linkColor range:range];

    switch (_underlineStyle) {
        case HILinkTextFieldUnderlineStyleAll:
            [string addAttribute:NSUnderlineStyleAttributeName
                           value:@(NSSingleUnderlineStyle)
                           range:range];
            break;

        case HILinkTextFieldUnderlineStyleUsername:
            [string addAttribute:NSUnderlineStyleAttributeName
                           value:@(NSSingleUnderlineStyle)
                           range:NSMakeRange(1, string.length - 1)];
            break;

        case HILinkTextFieldUnderlineStyleNone:
            break;
    }

    [string addAttribute:NSFontAttributeName value:self.font range:range];
    self.attributedStringValue = string;

    self.allowsEditingTextAttributes = YES;
    self.selectable = YES;
}

- (void)resetCursorRects {
    [self addCursorRect:[self bounds] cursor:[NSCursor pointingHandCursor]];
}

- (void)mouseDown:(NSEvent *)theEvent {
    [super mouseDown:theEvent];

    // focusing link makes it blue, regardless of NSForegroundColorAttributeName...
    [self.window makeFirstResponder:nil];
}

@end
