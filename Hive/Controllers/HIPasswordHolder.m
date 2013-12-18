#import "HIPasswordHolder.h"

@interface HIPasswordHolder ()

@property (nonatomic, strong) NSMutableData *mutableDataPassword;

@end

@implementation HIPasswordHolder

- (void)dealloc {
    if (self.mutableDataPassword) {
        // The owner should have called clear right away.
        // Who knows how long it might have been retained.
        HILogWarn(@"Error: Password was not wiped from memory until deallocation.");
        [self clear];
    }
}

- (id)initWithString:(NSString *)password {
    self = [super init];
    if (self) {
        _mutableDataPassword = [[password dataUsingEncoding:NSUTF16StringEncoding] mutableCopy];
        [self stripByteOrderMark];
    }
    return self;
}

- (void)stripByteOrderMark {
    uint16_t first = ((uint16_t *) _mutableDataPassword.bytes)[0];
    if (first == L'\ufeff' || first == L'\ufffe') {
        [self.mutableDataPassword replaceBytesInRange:NSMakeRange(0, self.mutableDataPassword.length)
                                            withBytes:_mutableDataPassword.bytes + 2
                                               length:self.mutableDataPassword.length - 2];
    }
}

- (NSData *)data {
    return self.mutableDataPassword;
}

- (void)clear {
    [self.mutableDataPassword resetBytesInRange:NSMakeRange(0, self.mutableDataPassword.length)];
    self.mutableDataPassword = nil;
}

@end
