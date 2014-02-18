@class HIBitcoinURL;
@class HISendBitcoinsWindowController;

/*
 Service for handling bitcoin: URLs.
 */
@interface HIBitcoinURLService : NSObject

+ (HIBitcoinURLService *)sharedService;

- (BOOL)handleBitcoinURLString:(NSString *)bitcoinURLString;
- (BOOL)applyURLString:(NSString *)bitcoinURLString toSendWindow:(HISendBitcoinsWindowController *)window;

@end
