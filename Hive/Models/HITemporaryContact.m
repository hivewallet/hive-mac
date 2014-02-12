//
//  HITemporaryContact.m
//  Hive
//
//  Created by Jakub Suder on 12/02/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HITemporaryContact.h"

@implementation HITemporaryContact {
    NSString *_name;
}

@synthesize
    firstname = _firstname,
    lastname = _lastname,
    email = _email,
    addresses = _addresses,
    avatar = _avatar,
    name = _name;

- (id)initWithName:(NSString *)name address:(NSString *)addressHash {
    self = [super init];

    if (self) {
        _name = [name copy];

        HITemporaryAddress *address = [[HITemporaryAddress alloc] init];
        address.address = addressHash;
        _addresses = [NSSet setWithObject:address];
    }

    return self;
}

- (NSImage *)avatarImage {
    return [NSImage imageNamed:@"avatar-empty"];
}

- (BOOL)canBeRemoved {
    return NO;
}

- (BOOL)canEditAddresses {
    return NO;
}

- (void)addAddressesObject:(HIAddress *)value {
    NSAssert(self.canEditAddresses, @"This object's addresses cannot be edited.");
}

@end


@implementation HITemporaryAddress

- (NSString *)addressSuffixWithCaption {
    return self.address;
}

@end
