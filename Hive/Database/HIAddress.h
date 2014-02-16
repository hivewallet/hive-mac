//
//  HIAddress.h
//  Hive
//
//  Created by Bazyli Zygan on 06.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@class HIContact;

extern NSString * const HIAddressEntity;


/*
 Represents a contact's single Bitcoin address. Includes a hash and a label/caption.
 */

@interface HIAddress : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * caption;
@property (nonatomic, retain) HIContact *contact;

@property (nonatomic, copy, readonly) NSString *addressWithCaption;

@end
