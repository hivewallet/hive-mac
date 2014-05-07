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
                return [self handlePaymentRequestURL:bitcoinURL.paymentRequestURL fromBitcoinURL:bitcoinURL];
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
        return [self handlePaymentRequestURL:bitcoinURL.paymentRequestURL fromBitcoinURL:bitcoinURL];
    }
}

- (BOOL)handlePaymentRequestURL:(NSString *)URLString fromBitcoinURL:(HIBitcoinURL *)bitcoinURL {
    NSURL *URL = [NSURL URLWithString:URLString];

    if (URL) {
        HIBitcoinManager *manager = [HIBitcoinManager defaultManager];
        NSError *callError = nil;

        [manager openPaymentRequestFromURL:URLString
                                     error:&callError
                                  callback:^(NSError *loadError, int sessionId, NSDictionary *data) {

                                      HIAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];

                                      // TODO hide loading spinner

                                      if (loadError) {
                                          [appDelegate handlePaymentRequestLoadError:loadError];
                                      } else {
                                          data = [self extendPaymentRequestData:data withBitcoinURLDetails:bitcoinURL];

                                          HISendBitcoinsWindowController *window = [appDelegate sendBitcoinsWindow];
                                          [window showPaymentRequest:sessionId details:data];
                                          [window showWindow:self];
                                      }
                                  }];

        if (callError) {
            // this should never happen, because only a URL error can be returned here,
            // and URLWithString: should return nil if the URL is not correct

            [self handlePaymentRequestURLErrorForURL:URLString];
            return NO;
        } else {
            // TODO show loading spinner
            return YES;
        }
    } else {
        [self handlePaymentRequestURLErrorForURL:URLString];
        return NO;
    }
}

- (void)handlePaymentRequestURLErrorForURL:(NSString *)URLString {
    NSString *title = NSLocalizedString(@"This payment request link is invalid.",
                                        @"Alert title when URL to a payment request file is not valid");

    NSString *message = NSLocalizedString(@"\"%@\" is not a valid URL.",
                                          @"Alert message when URL to a payment request file is not valid");

    NSAlert *alert = [NSAlert alertWithMessageText:title
                                     defaultButton:NSLocalizedString(@"OK", @"OK button title")
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:message, URLString];
    [alert runModal];
}

- (NSDictionary *)extendPaymentRequestData:(NSDictionary *)data withBitcoinURLDetails:(HIBitcoinURL *)bitcoinURL {
    NSMutableDictionary *extended = [NSMutableDictionary dictionaryWithDictionary:data];

    extended[@"bitcoinURLAmount"] = @(bitcoinURL.amount);

    if (bitcoinURL.address) {
        extended[@"bitcoinURLAddress"] = bitcoinURL.address;
    }

    if (bitcoinURL.label) {
        extended[@"bitcoinURLLabel"] = bitcoinURL.label;
    }

    if (bitcoinURL.message) {
        extended[@"bitcoinURLMessage"] = bitcoinURL.message;
    }

    return [NSDictionary dictionaryWithDictionary:extended];
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
