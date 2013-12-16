//
//  HIProfile.h
//  Hive
//
//  Created by Jakub Suder on 02.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HIPerson.h"

@class HIAddress;

/*
 This is a representation of user's profile data (stored in NSUserDefaults) with an API partially compatible
 with HIContact/HIAddress, so that it can be used as a contact in some view controllers.
 */

@interface HIProfile : NSObject<HIPerson>

@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *firstname;
@property (nonatomic, strong) NSString *lastname;
@property (nonatomic, readonly, getter = name) NSString *name;
@property (nonatomic, strong) NSSet *addresses;
@property (nonatomic, strong) NSData *avatar;
@property (nonatomic, readonly, getter = avatarImage) NSImage *avatarImage;

- (BOOL)canBeRemoved;
- (BOOL)canEditAddresses;

@end

@interface HIProfileAddress : NSObject

@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *caption;
@property (nonatomic, strong) HIProfile *contact;

@end
