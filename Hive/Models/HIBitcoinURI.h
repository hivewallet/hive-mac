//
//  HIBitcoinURI.h
//  Hive
//
//  Created by Jakub Suder on 23.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

/*
 Represents a bitcoin: URI that opens a send window when clicked e.g. in a browser.
 */

@interface HIBitcoinURI : NSObject

@property (readonly) BOOL valid;
@property (readonly) NSString *URIString;
@property (readonly) NSString *address;
@property (readonly) NSDictionary *parameters;
@property (readonly) NSString *label;
@property (readonly) NSString *message;
@property (readonly) NSString *paymentRequestURL;
@property (readonly) satoshi_t amount;

- (instancetype)initWithURIString:(NSString *)URI;

@end
