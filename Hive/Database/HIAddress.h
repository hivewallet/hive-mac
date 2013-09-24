//
//  HIAddress.h
//  Hive
//
//  Created by Bazyli Zygan on 06.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HIContact;

@interface HIAddress : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * caption;
@property (nonatomic, retain) HIContact *contact;

@property (nonatomic, readonly) NSString *addressSuffix;
@property (nonatomic, readonly) NSString *addressSuffixWithCaption;

+ (NSString *)truncateAddress:(NSString *)address;

@end
