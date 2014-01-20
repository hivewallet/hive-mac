@class HIPasswordHolder;

/*
 Common input and validation handler for repeated password input.
 */
@interface HIPasswordCreationInputHandler : NSObject

@property (nonatomic, strong) IBOutlet NSTextField *passwordField;
@property (nonatomic, strong) IBOutlet NSTextField *repeatedPasswordField;

- (void)resetInput;
- (void)textDidChangeInTextField:(NSTextField *)textField;
- (void)editingDidEnd;
- (void)finishWithPasswordHolder:(void (^)(HIPasswordHolder *passwordHolder))block;

@end
