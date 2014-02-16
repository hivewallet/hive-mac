/* Notification that the preferred Bitcoin format changed. */
extern NSString *const HIPreferredFormatChangeNotification;

/*
 This service handles the various Bitcoin formats.
 */
@interface HIBitcoinFormatService : NSObject

@property (nonatomic, copy, readonly) NSString *decimalSeparator;
@property (nonatomic, copy, readonly) NSArray *availableFormats;
@property (nonatomic, copy) NSString *preferredFormat;
@property (nonatomic, copy) NSLocale *locale;

+ (HIBitcoinFormatService *)sharedService;

/* Formats a bitcoin value in the user's preferred format including the format designator.
 e.g. 255 mBTC
 */
- (NSString *)stringWithUnitForBitcoin:(satoshi_t)satoshi;

/* Formats a bitcoin value in the user's preferred format.
 e.g. 255
 */
- (NSString *)stringForBitcoin:(satoshi_t)satoshi;

/* Formats a bitcoin value in a specific format.
 e.g. 255
 */
- (NSString *)stringForBitcoin:(satoshi_t)satoshi
                    withFormat:(NSString *)format;

/* Parses a bitcoin value in a specific format. */
- (satoshi_t)parseString:(NSString *)string
              withFormat:(NSString *)format
                   error:(NSError **)error;

@end
