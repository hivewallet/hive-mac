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

@property (nonatomic, readonly) BOOL valid;
@property (nonatomic, copy, readonly) NSString *URIString;
@property (nonatomic, copy, readonly) NSString *address;
@property (nonatomic, copy, readonly) NSDictionary *parameters;
@property (nonatomic, copy, readonly) NSString *label;
@property (nonatomic, copy, readonly) NSString *message;
@property (nonatomic, copy, readonly) NSString *paymentRequestURL;
@property (nonatomic, readonly) satoshi_t amount;

- (instancetype)initWithURIString:(NSString *)URI;

@end
