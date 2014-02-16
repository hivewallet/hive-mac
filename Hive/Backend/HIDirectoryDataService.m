#import "HIDirectoryDataService.h"

#import "NPZip.h"

@implementation HIDirectoryDataService

+ (HIDirectoryDataService *)sharedService {
    static HIDirectoryDataService *sharedService = nil;
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        sharedService = [[self class] new];
    });

    return sharedService;
}

- (NSData *)dataForPath:(NSString *)path
            inDirectory:(NSURL *)directory {

    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:directory.path isDirectory:&isDirectory];

    if (exists) {
        if (isDirectory) {
            return [NSData dataWithContentsOfURL:[directory URLByAppendingPathComponent:path]];
        } else {
            NPZip *zip = [NPZip archiveWithFile:directory.path];
            return [zip dataForEntryNamed:path];
        }
    }
    return nil;
}

@end
