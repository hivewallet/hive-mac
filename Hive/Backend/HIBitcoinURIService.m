#import <BitcoinJKit/BitcoinJKit.h>
#import "HIBitcoinURI.h"
#import "HIBitcoinURIService.h"
#import "HISendBitcoinsWindowController.h"
#import "HITemporaryContact.h"

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
            return NO;
        }
    } else {
        // not a bitcoin URI at all, try loading a payment request
        return [self handlePaymentRequestURL:bitcoinURI.paymentRequestURL fromBitcoinURI:bitcoinURI];
    }
}

- (BOOL)handlePaymentRequestURL:(NSString *)URLString fromBitcoinURI:(HIBitcoinURI *)bitcoinURI {
    NSURL *URL = [NSURL URLWithString:URLString];

    if (URL) {
        HIAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
        HIBitcoinManager *manager = [HIBitcoinManager defaultManager];
        NSError *callError = nil;

        __block HISendBitcoinsWindowController *window;

        [manager openPaymentRequestFromURL:URLString
                                     error:&callError
                                  callback:^(NSError *loadError, int sessionId, NSDictionary *data) {
                                      if (loadError) {
                                          [window close];
                                          [appDelegate handlePaymentRequestLoadError:loadError];
                                      } else {
                                          data = [self extendPaymentRequestData:data withBitcoinURIDetails:bitcoinURI];

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
