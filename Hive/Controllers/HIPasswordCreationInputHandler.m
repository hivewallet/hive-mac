#import "HIPasswordCreationInputHandler.h"
#import "HIPasswordHolder.h"

@implementation HIPasswordCreationInputHandler

- (void)resetInput {
    self.passwordField.stringValue = @"";
    self.repeatedPasswordField.stringValue = @"";
}

- (BOOL)arePasswordsEqual {
    return [self.passwordField.stringValue isEqualToString:self.repeatedPasswordField.stringValue];
}

- (void)textDidChangeInTextField:(NSTextField *)textField {
    if (textField != self.repeatedPasswordField) {
        [self editingDidEnd];
    } else {
        [self clearValidationProblemsIfPasswordsAreEqual];
    }
}

- (void)editingDidEnd {
    if ([self arePasswordsEqual]) {
        [self clearValidationProblems];
    } else if (self.repeatedPasswordField.stringValue.length > 0) {
        [self setRepeatedPasswordBackgroundColor:[[NSColor redColor] colorWithAlphaComponent:0.25]];
    }
}

- (void)clearValidationProblemsIfPasswordsAreEqual {
    if ([self arePasswordsEqual]) {
        [self clearValidationProblems];
    }
}

- (void)clearValidationProblems {
    [self setRepeatedPasswordBackgroundColor:[NSColor whiteColor]];
}

- (void)setRepeatedPasswordBackgroundColor:(NSColor *)color {
    self.repeatedPasswordField.backgroundColor = color;

    // stupid Cocoa, y u no update the color
    [self.repeatedPasswordField setEditable:NO];
    [self.repeatedPasswordField setEditable:YES];
}

- (void)finishWithPasswordHolder:(void (^)(HIPasswordHolder *passwordHolder))block {
    if (![self arePasswordsEqual]) {
        [self editingDidEnd];
        [self.repeatedPasswordField becomeFirstResponder];
        return;
    }

    @autoreleasepool {
        HIPasswordHolder *changedPasswordHolder =
            [[HIPasswordHolder alloc] initWithString:self.passwordField.stringValue];
        @try {
            block(changedPasswordHolder);
        } @finally {
            [changedPasswordHolder clear];
        }
    }
}

@end
