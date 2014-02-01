/*
 Reads a file from a directory or zipped directory.
 */
@interface HIDirectoryDataService : NSObject

+ (HIDirectoryDataService *)sharedService;

- (NSData *)dataForPath:(NSString *)path
            inDirectory:(NSURL *)directory;

@end
