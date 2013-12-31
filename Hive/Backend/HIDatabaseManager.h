//
//  HIDatabaseManager.h
//  Hive
//
//  Created by Jakub Suder on 10.12.13.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 Manages Core Data helper objects (model, context, store coordinator).
 */

@interface HIDatabaseManager : NSObject

+ (HIDatabaseManager *)sharedManager;

@property (readonly, nonatomic) NSManagedObjectContext *managedObjectContext;

- (void)backupStoreToDirectory:(NSURL *)backupLocation error:(NSError **)error;

@end
