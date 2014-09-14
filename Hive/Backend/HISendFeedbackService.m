#import "HISendFeedbackService.h"

@implementation HISendFeedbackService

+ (HISendFeedbackService *)sharedService {
    static HISendFeedbackService *sharedService = nil;
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        sharedService = [[self class] new];
    });

    return sharedService;
}

- (void)sendSupportEmail {

    NSString *escapedTo = [self escapeForURL:@"macsupport@hivewallet.zendesk.com"];
    NSString *escapedSubject = [self escapeForURL:[self createSubject]];
    NSString *escapedBody = [self escapeForURL:[self createBody]];

    NSString *url = [NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@", escapedTo, escapedSubject, escapedBody];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

- (NSString *)escapeForURL:(NSString *)body {
    return [body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)createSubject {
    NSBundle *bundle = [NSBundle mainBundle];
    NSArray *preferredLanguages = [NSBundle preferredLocalizationsFromArray:[NSBundle mainBundle].localizations];

    return [NSString stringWithFormat:@"Feedback for %@ %@/%@ (%@)",
                                      [bundle objectForInfoDictionaryKey:@"CFBundleName"],
                                      [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                      [bundle objectForInfoDictionaryKey:@"CFBundleVersion"],
                                      preferredLanguages[0]];
}

- (NSString *)createBody {
    return NSLocalizedString(@"(Please write in English if possible.)", @"Body for feedback emails");
}

@end
