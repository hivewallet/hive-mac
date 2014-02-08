#import "HISendFeedbackService.h"

@implementation HISendFeedbackService

+ (HISendFeedbackService *)sharedService {
    static HISendFeedbackService *sharedService = nil;
    static dispatch_once_t oncePredicate;

    if (!sharedService) {
        dispatch_once(&oncePredicate, ^{
            sharedService = [[self class] new];
        });
    }

    return sharedService;
}

- (void)sendSupportEmail {

    NSString *escapedTo = [self escapeForUrl:@"macsupport@hivewallet.com"];
    NSString *escapedSubject = [self escapeForUrl:[self createSubject]];
    NSString *escapedBody = [self escapeForUrl:[self createBody]];

    NSString *url = [NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@", escapedTo, escapedSubject, escapedBody];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

- (NSString *)escapeForUrl:(NSString *)body {
    return [body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)createSubject {

    NSMutableString *text = [NSMutableString new];
    NSBundle *bundle = [NSBundle mainBundle];

    [text appendString:NSLocalizedString(@"Feedback", @"Subject for feedback emails")];
    [text appendString:@" "];
    [text appendString:[bundle objectForInfoDictionaryKey:@"CFBundleName"]];
    [text appendString:@" "];
    [text appendString:[bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    [text appendString:@" ("];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *languages = [userDefaults objectForKey:@"AppleLanguages"];
    [text appendString:languages[0]];
    [text appendString:@")\n"];

    return text;
}

- (NSString *)createBody {
    return NSLocalizedString(@"(Please write in English if possible.)", @"Body for feedback emails");
}

@end
