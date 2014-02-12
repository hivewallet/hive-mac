//
//  HITemporaryContact.h
//  Hive
//
//  Created by Jakub Suder on 12/02/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HIPerson.h"

@class HIAddress;

/*
 This is a temporary HIContact object that isn't saved to the database; used e.g. for passing contact data from
 bitcoin: URLs to the Send window.
 */

@interface HITemporaryContact : NSObject<HIPerson>

- (id)initWithName:(NSString *)name address:(NSString *)addressHash;

@end


@interface HITemporaryAddress : NSObject

@property (nonatomic, strong) NSString *address;

@end
