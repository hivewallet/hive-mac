@class HIPasswordHolder;

/*
 Common input and validation handler for repeated password input.
 */
@interface HIPasswordCreationInputHandler : NSObject

- (void)resetInput;
- (void)textDidChangeInTextField:(NSTextField *)textField;
- (void)editingDidEnd;
- (void)finishWithPasswordHolder:(void (^)(HIPasswordHolder *passwordHolder))block;

@end
