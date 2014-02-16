#import "HIBitcoinUrlService.h"

#import "HIBitcoinURL.h"
#import "HISendBitcoinsWindowController.h"
#import "HITemporaryContact.h"

@implementation HIBitcoinUrlService

+ (HIBitcoinUrlService *)sharedService {
    static HIBitcoinUrlService *sharedService = nil;
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        sharedService = [[self class] new];
    });

    return sharedService;
}

- (BOOL)handleBitcoinUrlString:(NSString *)bitcoinUrlString {
    HILogDebug(@"Opening bitcoin URL %@", bitcoinUrlString);

    HIBitcoinURL *bitcoinURL = [[HIBitcoinURL alloc] initWithURLString:bitcoinUrlString];
    HILogDebug(@"Parsed URL as %@", bitcoinURL);

    if (bitcoinURL.valid) {
        HIAppDelegate *appDelegate = [NSApplication sharedApplication].delegate;
        HISendBitcoinsWindowController *window = [appDelegate sendBitcoinsWindow];
        [self applyUrl:bitcoinURL toSendWindow:window];
        [window showWindow:self];
    }

    return bitcoinURL.valid;
}

- (BOOL)applyUrlString:(NSString *)bitcoinUrlString toSendWindow:(HISendBitcoinsWindowController *)window {
    HIBitcoinURL *bitcoinURL = [[HIBitcoinURL alloc] initWithURLString:bitcoinUrlString];
    HILogDebug(@"Parsed URL as %@", bitcoinUrlString);

    if (bitcoinURL.valid) {
        [self applyUrl:bitcoinURL toSendWindow:window];
    }

    return bitcoinURL.valid;
}

- (void)applyUrl:(HIBitcoinURL *)bitcoinURL toSendWindow:(HISendBitcoinsWindowController *)window {
    if (bitcoinURL.address) {
        if (bitcoinURL.label) {
            id<HIPerson> contact = [self createContactForUrl:bitcoinURL];
            [window selectContact:contact address:contact.addresses.anyObject];
            [window lockAddress];
        } else {
            [window setLockedAddress:bitcoinURL.address];
        }
    }

    if (bitcoinURL.amount) {
        [window setLockedAmount:bitcoinURL.amount];
    }
}

- (id<HIPerson>)createContactForUrl:(HIBitcoinURL *)bitcoinURL {
    return [[HITemporaryContact alloc] initWithName:bitcoinURL.label address:bitcoinURL.address];
}

@end
