//
//  HIProfile.h
//  Hive
//
//  Created by Jakub Suder on 02.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIPerson.h"

@class HIAddress;

/*
 This is a representation of user's profile data (stored in NSUserDefaults) with an API partially compatible
 with HIContact/HIAddress, so that it can be used as a contact in some view controllers.
 */

@interface HIProfile : NSObject<HIPerson>

@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *firstname;
@property (nonatomic, copy) NSString *lastname;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy) NSSet *addresses;
@property (nonatomic, copy) NSData *avatar;
@property (nonatomic, readonly) NSImage *avatarImage;

- (BOOL)canBeRemoved;
- (BOOL)canEditAddresses;
- (BOOL)hasName;

@end

@interface HIProfileAddress : NSObject

@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) NSString *caption;
@property (nonatomic, strong) HIProfile *contact;

@end
