#import <BitcoinJKit/BitcoinJKit.h>
#import "HIBitcoinURL.h"
#import "HIBitcoinURLService.h"
#import "HISendBitcoinsWindowController.h"
#import "HITemporaryContact.h"

@implementation HIBitcoinURLService

+ (HIBitcoinURLService *)sharedService {
    static HIBitcoinURLService *sharedService = nil;
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        sharedService = [[self class] new];
    });

    return sharedService;
}

- (BOOL)handleBitcoinURLString:(NSString *)bitcoinURLString {
    HILogDebug(@"Opening bitcoin URL %@", bitcoinURLString);

    HIBitcoinURL *bitcoinURL = [[HIBitcoinURL alloc] initWithURLString:bitcoinURLString];
    HILogDebug(@"Parsed URL as %@", bitcoinURL);

    HIAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];

    if (bitcoinURL) {
        if (bitcoinURL.valid) {
            if (bitcoinURL.paymentRequestURL) {
                return [self handlePaymentRequestURL:bitcoinURL.paymentRequestURL];
            } else {
                HISendBitcoinsWindowController *window = [appDelegate sendBitcoinsWindow];
                [self applyURL:bitcoinURL toSendWindow:window];
                [window showWindow:self];
                return YES;
            }
        } else {
            // invalid bitcoin URL
            return NO;
        }
    } else {
        // not a bitcoin URL at all, try loading a payment request
        return [self handlePaymentRequestURL:bitcoinURL.paymentRequestURL];
    }
}

- (BOOL)handlePaymentRequestURL:(NSString *)URLString {
    NSURL *URL = [NSURL URLWithString:URLString];

    if (URL) {
        // TODO show loading spinner

        HIBitcoinManager *manager = [HIBitcoinManager defaultManager];
        [manager openPaymentRequestFromURL:URLString
                                  callback:^(NSError *error, int sessionId, NSDictionary *data) {
                                      if (error) {
                                          // TODO show error
                                      } else {
                                          HIAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
                                          HISendBitcoinsWindowController *window = [appDelegate sendBitcoinsWindow];
                                          [window showPaymentRequest:sessionId details:data];
                                          [window showWindow:self];
                                      }
                                  }];
        return YES;
    } else {
        // TODO handle error
        return NO;
    }
}

- (BOOL)applyURLString:(NSString *)bitcoinURLString toSendWindow:(HISendBitcoinsWindowController *)window {
    HIBitcoinURL *bitcoinURL = [[HIBitcoinURL alloc] initWithURLString:bitcoinURLString];
    HILogDebug(@"Parsed URL as %@", bitcoinURLString);

    if (bitcoinURL.valid) {
        [self applyURL:bitcoinURL toSendWindow:window];
    }

    return bitcoinURL.valid;
}

- (void)applyURL:(HIBitcoinURL *)bitcoinURL toSendWindow:(HISendBitcoinsWindowController *)window {
    if (bitcoinURL.address) {
        if (bitcoinURL.label || bitcoinURL.message) {
            id<HIPerson> contact = [self createContactForURL:bitcoinURL];
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

- (id<HIPerson>)createContactForURL:(HIBitcoinURL *)bitcoinURL {
    return [[HITemporaryContact alloc] initWithName:(bitcoinURL.label ?: bitcoinURL.message)
                                            address:bitcoinURL.address];
}

@end
