//
//  HIBackupManager.h
//  Hive
//
//  Created by Jakub Suder on 23.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HIBackupManager : NSObject

@property (readonly) NSArray *adapters;

+ (HIBackupManager *)sharedManager;

@end
