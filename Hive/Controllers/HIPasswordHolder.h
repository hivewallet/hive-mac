/*
 Password storage that makes an effort to remove the password from memory.
 */
@interface HIPasswordHolder : NSObject

/*
 The password as an UTF8 string.
 Never copy this property unless you destroy the copy right away.
 */
@property (nonatomic, strong, readonly) NSData *data;

- (id)initWithString:(NSString *)password;

- (void)clear;

@end
