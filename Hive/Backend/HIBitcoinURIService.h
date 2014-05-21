@class HIBitcoinURI;
@class HISendBitcoinsWindowController;

/*
 Service for handling bitcoin: URIs.
 */
@interface HIBitcoinURIService : NSObject

+ (HIBitcoinURIService *)sharedService;

- (BOOL)handleBitcoinURIString:(NSString *)bitcoinURIString;
- (BOOL)applyURIString:(NSString *)bitcoinURIString toSendWindow:(HISendBitcoinsWindowController *)window;
- (void)showQRCodeErrorForURI:(NSString *)URIString;

@end
