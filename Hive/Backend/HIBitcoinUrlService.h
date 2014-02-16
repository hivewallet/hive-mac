@class HIBitcoinURL;
@class HISendBitcoinsWindowController;

/*
 Service for handling bitcoin: URLs.
 */
@interface HIBitcoinUrlService : NSObject

+ (HIBitcoinUrlService *)sharedService;

- (BOOL)handleBitcoinUrlString:(NSString *)bitcoinUrlString;
- (BOOL)applyUrlString:(NSString *)bitcoinUrlString toSendWindow:(HISendBitcoinsWindowController *)window;

@end
