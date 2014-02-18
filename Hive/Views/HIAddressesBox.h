/*
 An HIBox, containing HICopyViews for multiple bitcoin addresses.
 */
@interface HIAddressesBox : NSView

@property (nonatomic, copy) NSArray *addresses;
@property (nonatomic, assign) BOOL observingWallet;
@property (nonatomic, assign) BOOL showsQRCode;

@end
