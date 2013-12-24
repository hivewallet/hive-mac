typedef uint64 satoshi_t;

/*
 This service handles the various Bitcoin formats.
 */
@interface HIBitcoinFormatService : NSObject

@property (nonatomic, copy, readonly) NSArray *availableFormats;
@property (nonatomic, copy) NSString *preferredFormat;

+ (HIBitcoinFormatService *)sharedService;

/* Formats a bitcoin value in the user's preferred format. */
- (NSString *)stringForBitcoin:(satoshi_t)satoshi;

/* Formats a bitcoin value in a specific format. */
- (NSString *)stringForBitcoin:(satoshi_t)satoshi
                    withFormat:(NSString *)format;

@end
