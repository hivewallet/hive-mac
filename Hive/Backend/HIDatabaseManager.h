//
//  HIDatabaseManager.h
//  Hive
//
//  Created by Jakub Suder on 10.12.13.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HIDatabaseManager : NSObject

+ (HIDatabaseManager *)sharedManager;

@property (readonly, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
