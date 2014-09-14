//
//  HIBackupManager.h
//  Hive
//
//  Created by Jakub Suder on 23.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

@interface HIBackupManager : NSObject

@property (nonatomic, readonly) NSArray *allAdapters;
@property (nonatomic, readonly) NSArray *visibleAdapters;

+ (HIBackupManager *)sharedManager;
- (void)initializeAdapters;
- (void)resetSettings;
- (void)performBackups;

@end
