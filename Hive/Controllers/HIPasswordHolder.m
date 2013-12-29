#import "HIPasswordHolder.h"

@interface HIPasswordHolder ()

@property (nonatomic, strong) NSMutableData *mutableDataPassword;
@property (nonatomic, strong) NSData *dataPasswordSubset;

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
        NSData *data = [password dataUsingEncoding:NSUTF16StringEncoding];
        if ([data isKindOfClass:[NSMutableData class]]) {
            _mutableDataPassword = (NSMutableData *)data;
        } else {
            // Doesn't happen on OS X 10.9.
            HILogWarn(@"Leaking password into memory");
            _mutableDataPassword = [data mutableCopy];
        }
        _dataPasswordSubset = _mutableDataPassword;

        [self stripByteOrderMark];
    }
    return self;
}

- (void)stripByteOrderMark {
    uint16_t first = ((uint16_t *) _mutableDataPassword.bytes)[0];
    if (first == L'\ufeff' || first == L'\ufffe') {
        self.dataPasswordSubset = [[NSData alloc] initWithBytesNoCopy:(void *)_mutableDataPassword.bytes + 2
                                                               length:self.mutableDataPassword.length - 2
                                                         freeWhenDone:NO];
    }
}

- (NSData *)data {
    return self.dataPasswordSubset;
}

- (void)clear {
    [self.mutableDataPassword resetBytesInRange:NSMakeRange(0, self.mutableDataPassword.length)];
    self.mutableDataPassword = nil;
}

@end
