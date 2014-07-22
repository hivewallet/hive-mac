//
//  HISyncingAppAdapter.h
//  Hive
//
//  Created by Jakub Suder on 22/07/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HIBackupAdapter.h"

extern const NSInteger HISyncingAppAdapterNotConfigured;
extern const NSInteger HISyncingAppAdapterCouldntComplete;
extern const NSInteger HISyncingAppAdapterNotRunning;


@interface HISyncingAppAdapter : HIBackupAdapter

@property (nonatomic, copy) NSString *backupLocation;
@property (nonatomic, copy) NSDate *lastRegisteredBackup;
@property (nonatomic, readonly) NSString *errorDomain;

- (NSString *)backupFolderName;
- (NSArray *)syncFolders;
- (NSArray *)existingSyncFolders;
- (NSString *)syncFolderFromDetectionScript:(NSString *)scriptName;

@end
