/*
 This service handles the various Bitcoin formats.
 */
@interface HIBitcoinFormatService : NSObject

@property (nonatomic, copy, readonly) NSString *decimalSeparator;
@property (nonatomic, copy, readonly) NSArray *availableFormats;
@property (nonatomic, copy) NSString *preferredFormat;

+ (HIBitcoinFormatService *)sharedService;

/* Formats a bitcoin value in the user's preferred format. */
- (NSString *)stringForBitcoin:(satoshi_t)satoshi;

/* Formats a bitcoin value in a specific format. */
- (NSString *)stringForBitcoin:(satoshi_t)satoshi
                    withFormat:(NSString *)format;

/* Parses a bitcoin value in a specific format. */
- (satoshi_t)parseString:(NSString *)string
              withFormat:(NSString *)format
                   error:(NSError **)error;

@end
