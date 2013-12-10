#import "HIPasswordHolder.h"

@interface HIPasswordHolder ()

@property (nonatomic, strong, readonly) NSMutableData *mutableDataPassword;

@end

@implementation HIPasswordHolder

- (id)initWithString:(NSString *)password {
    self = [super init];
    if (self) {
        _mutableDataPassword = [[password dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    }
    return self;
}

- (void)clear {
    [self.mutableDataPassword resetBytesInRange:NSMakeRange(0, self.mutableDataPassword.length)];
}

@end
