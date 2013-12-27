@interface NSDecimalNumber(HISatoshiConversion)

@property (nonatomic, assign, readonly) satoshi_t hiSatoshi;

+ (NSDecimalNumber *)hiDecimalNumberWithSatoshi:(satoshi_t)satoshi;

@end
