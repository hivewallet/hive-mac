typedef uint64 satoshi_t;

/*
 This service handles the various Bitcoin formats.
 */
@interface HIBitcoinFormatService : NSObject

@property (nonatomic, copy, readonly) NSArray *availableFormats;
@property (nonatomic, copy) NSString *preferredFormat;

+ (HIBitcoinFormatService *)sharedService;

@end
