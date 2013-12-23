typedef uint64 satoshi_t;

/*
 This service handles the various Bitcoin formats.
 */
@interface HIBitcoinFormatService : NSObject

+ (HIBitcoinFormatService *)sharedService;

@property (nonatomic, copy, readonly) NSArray *availableFormats;

@end
