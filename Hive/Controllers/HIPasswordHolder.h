/*
 Password storage that makes an effort to remove the password from memory.
 */
@interface HIPasswordHolder : NSObject

/*
 The password as an UTF-16 string.
 Never copy this property unless you destroy the copy right away.
 */
@property (nonatomic, strong, readonly) NSData *data;

- (instancetype)initWithString:(NSString *)password;

- (void)clear;

@end
