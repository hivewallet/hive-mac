#import "HIBitcoinURI.h"
#import "HIBitcoinURIService.h"
#import "HISendBitcoinsWindowController.h"
#import "HITemporaryContact.h"
#import "NSAlert+Hive.h"

@implementation HIBitcoinURIService

+ (HIBitcoinURIService *)sharedService {
    static HIBitcoinURIService *sharedService = nil;
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        sharedService = [[self class] new];
    });

    return sharedService;
}

- (BOOL)handleBitcoinURIString:(NSString *)bitcoinURIString {
    HILogDebug(@"Opening bitcoin URI %@", bitcoinURIString);

    HIBitcoinURI *bitcoinURI = [[HIBitcoinURI alloc] initWithURIString:bitcoinURIString];
    HILogDebug(@"Parsed URI as %@", bitcoinURI);

    HIAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];

    if (bitcoinURI) {
        if (bitcoinURI.valid) {
            if (bitcoinURI.paymentRequestURL) {
                return [self handlePaymentRequestURL:bitcoinURI.paymentRequestURL fromBitcoinURI:bitcoinURI];
            } else {
                HISendBitcoinsWindowController *window = [appDelegate sendBitcoinsWindow];
                [self applyURI:bitcoinURI toSendWindow:window];
                [window showWindow:self];
                return YES;
            }
        } else {
            // invalid bitcoin URI
            [self handlePaymentURIErrorForURI:bitcoinURIString];
            return NO;
        }
    } else {
        // not a bitcoin URI at all, try loading a payment request
        return [self handlePaymentRequestURL:bitcoinURIString fromBitcoinURI:nil];
    }
}

- (BOOL)handlePaymentRequestURL:(NSString *)URLString fromBitcoinURI:(HIBitcoinURI *)bitcoinURI {
//    NSURL *URL = [NSURL URLWithString:URLString];

//    if (URL) {
        /*HIAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
        HIBitcoinManager *manager = [HIBitcoinManager defaultManager];
        NSError *callError = nil;

        __block HISendBitcoinsWindowController *window;

        HILogDebug(@"Loading remote payment request from %@", URLString);

        [manager openPaymentRequestFromURL:URLString
                                     error:&callError
                                  callback:^(NSError *loadError, int sessionId, NSDictionary *data) {
                                      if (loadError) {
                                          [window close];
                                          [appDelegate handlePaymentRequestLoadError:loadError];
                                      } else {
                                          if (bitcoinURI) {
                                              data = [self extendPaymentRequestData:data
                                                              withBitcoinURIDetails:bitcoinURI];
                                          }

                                          [window hidePaymentRequestLoadingBox];
                                          [window showPaymentRequest:sessionId details:data];
                                      }
                                  }];

        if (callError) {
            // this should never happen, because only a URL error can be returned here,
            // and URLWithString: should return nil if the URL is not correct

            [self handlePaymentRequestURLErrorForURL:URLString];
            return NO;
        } else {
            window = [appDelegate sendBitcoinsWindow];
            [window showPaymentRequestLoadingBox];
            [window showWindow:self];

            return YES;
        }*/
//    } else {
        [self handlePaymentRequestURLErrorForURL:URLString];
        return NO;
//    }
}

- (void)handlePaymentRequestURLErrorForURL:(NSString *)URLString {
    HILogWarn(@"Payment request URL is invalid: %@", URLString);

    NSString *title = NSLocalizedString(@"This Bitcoin payment URL is invalid.",
                                        @"Alert title when payment request URL is not valid");

    NSString *message = NSLocalizedString(@"\"%@\" is not a valid URL.",
                                          @"Alert message when payment request URL is not valid");

    [[NSAlert hiOKAlertWithTitle:title format:message, URLString] runModal];
}

- (void)handlePaymentURIErrorForURI:(NSString *)URIString {
    HILogWarn(@"bitcoin: URI is invalid: %@", URIString);

    NSString *title = NSLocalizedString(@"This Bitcoin payment link is invalid.",
                                        @"Alert title when bitcoin: URI is not valid");

    NSString *message = NSLocalizedString(@"\"%@\" is not a valid payment link.",
                                          @"Alert message when bitcoin: URI is not valid");

    [[NSAlert hiOKAlertWithTitle:title format:message, URIString] runModal];
}

- (void)showQRCodeErrorForURI:(NSString *)URIString {
    HILogWarn(@"bitcoin: URI is invalid or can't be used to extract address: %@", URIString);

    NSString *title = NSLocalizedString(@"This QR code can't be used here.",
                                        @"Alert title when address can't be extracted from a bitcoin: URI");

    NSString *message = NSLocalizedString(@"Link included in this QR code (\"%@\") is invalid "
                                          @"or does not contain a Bitcoin address.",
                                          @"Alert message when address can't be extracted from a bitcoin: URI");

    [[NSAlert hiOKAlertWithTitle:title format:message, URIString] runModal];
}

- (NSDictionary *)extendPaymentRequestData:(NSDictionary *)data withBitcoinURIDetails:(HIBitcoinURI *)bitcoinURI {
    NSMutableDictionary *extended = [NSMutableDictionary dictionaryWithDictionary:data];

    extended[@"bitcoinURIAmount"] = @(bitcoinURI.amount);

    if (bitcoinURI.address) {
        extended[@"bitcoinURIAddress"] = bitcoinURI.address;
    }

    if (bitcoinURI.label) {
        extended[@"bitcoinURILabel"] = bitcoinURI.label;
    }

    if (bitcoinURI.message) {
        extended[@"bitcoinURIMessage"] = bitcoinURI.message;
    }

    return [NSDictionary dictionaryWithDictionary:extended];
}

- (BOOL)applyURIString:(NSString *)bitcoinURIString toSendWindow:(HISendBitcoinsWindowController *)window {
    HIBitcoinURI *bitcoinURI = [[HIBitcoinURI alloc] initWithURIString:bitcoinURIString];
    HILogDebug(@"Parsed URI as %@", bitcoinURIString);

    if (bitcoinURI.valid) {
        [self applyURI:bitcoinURI toSendWindow:window];
    } else {
        [self showQRCodeErrorForURI:bitcoinURIString];
    }

    return bitcoinURI.valid;
}

- (void)applyURI:(HIBitcoinURI *)bitcoinURI toSendWindow:(HISendBitcoinsWindowController *)window {
    if (bitcoinURI.address) {
        if (bitcoinURI.label) {
            id<HIPerson> contact = [self createContactForURI:bitcoinURI];
            [window selectContact:contact address:contact.addresses.anyObject];
            [window lockAddress];
        } else {
            [window setLockedAddress:bitcoinURI.address];
        }
    }

    if (bitcoinURI.amount) {
        [window setLockedAmount:bitcoinURI.amount];
    }

    if (bitcoinURI.message) {
        [window setDetailsText:bitcoinURI.message];
    }
}

- (id<HIPerson>)createContactForURI:(HIBitcoinURI *)bitcoinURI {
    return [[HITemporaryContact alloc] initWithName:bitcoinURI.label address:bitcoinURI.address];
}

@end
