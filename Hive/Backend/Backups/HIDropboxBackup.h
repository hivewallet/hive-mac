//
//  HIDropboxBackup.h
//  Hive
//
//  Created by Jakub Suder on 23.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIBackupAdapter.h"

extern NSString * const HIDropboxBackupError;
extern const NSInteger HIDropboxBackupNotConfigured;
extern const NSInteger HIDropboxBackupCouldntComplete;
extern const NSInteger HIDropboxBackupNotRunning;

@interface HIDropboxBackup : HIBackupAdapter

@end
