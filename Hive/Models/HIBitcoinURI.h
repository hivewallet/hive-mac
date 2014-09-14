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
@property (copy, readonly) NSString *URIString;
@property (copy, readonly) NSString *address;
@property (copy, readonly) NSDictionary *parameters;
@property (copy, readonly) NSString *label;
@property (copy, readonly) NSString *message;
@property (copy, readonly) NSString *paymentRequestURL;
@property (readonly) satoshi_t amount;

- (instancetype)initWithURIString:(NSString *)URI;

@end
