//
//  HIAddress.h
//  Hive
//
//  Created by Bazyli Zygan on 06.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

@class HIContact;

extern NSString * const HIAddressEntity;


/*
 Represents a contact's single Bitcoin address. Includes a hash and a label/caption.
 */

@interface HIAddress : NSManagedObject

@property (nonatomic, strong) NSString * address;
@property (nonatomic, strong) NSString * caption;
@property (nonatomic, strong) HIContact *contact;

@property (nonatomic, copy, readonly) NSString *addressWithCaption;

@end
