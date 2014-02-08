@interface HIBitcoinUrlService : NSObject

+ (HIBitcoinUrlService *)sharedService;

- (BOOL)handleBitcoinUrlString:(NSString *)bitcoinUrlString;

@end
