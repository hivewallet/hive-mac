//
//  HIBitcoinURL.h
//  Hive
//
//  Created by Jakub Suder on 23.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HIBitcoinURL : NSObject

@property (readonly) BOOL valid;
@property (readonly) NSString *URLString;
@property (readonly) NSString *address;
@property (readonly) NSDictionary *parameters;
@property (readonly) NSString *label;
@property (readonly) NSString *message;
@property (readonly) NSDecimalNumber *amount;

- (id)initWithURLString:(NSString *)URL;

@end
