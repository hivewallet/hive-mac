/*
 Service for handling bitcoin: URLs.
 */
@interface HIBitcoinUrlService : NSObject

+ (HIBitcoinUrlService *)sharedService;

- (BOOL)handleBitcoinUrlString:(NSString *)bitcoinUrlString;

@end
