#import "HILinkTextField.h"

@implementation HILinkTextField

- (void)setStringValue:(NSString *)aString
{
    [super setStringValue:aString];
    [self updateLink];
}

- (void)setHref:(NSString *)href
{
    _href = [href copy];
    [self updateLink];
}

- (void)updateLink
{
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:self.stringValue];
    NSRange range = NSMakeRange(0, string.length);
    [string addAttribute:NSLinkAttributeName value:_href range:range];
    [string addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
    [string addAttribute:NSUnderlineStyleAttributeName value:@(NSSingleUnderlineStyle) range:range];
    [string addAttribute:NSFontAttributeName value:self.font range:range];
    self.attributedStringValue = string;

    self.allowsEditingTextAttributes = YES;
    self.selectable = YES;
}

- (void)resetCursorRects
{
    [self addCursorRect:[self bounds] cursor:[NSCursor pointingHandCursor]];
}

@end
