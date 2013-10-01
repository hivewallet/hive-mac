//
//  HIApplication.h
//  Hive
//
//  Created by Bazyli Zygan on 27.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

extern NSString * const HIApplicationEntity;


@interface HIApplication : NSManagedObject

@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSURL * path;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, readonly, getter = icon) NSImage *icon;
@end
