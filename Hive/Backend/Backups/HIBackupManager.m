//
//  HIBackupManager.m
//  Hive
//
//  Created by Jakub Suder on 23.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIBackupAdapter.h"
#import "HIBackupManager.h"
#import "HIDropboxBackup.h"
#import "HITimeMachineBackup.h"

@implementation HIBackupManager

+ (HIBackupManager *)sharedManager {
    static HIBackupManager *_sharedManager = nil;
    static dispatch_once_t oncePredicate;

    if (!_sharedManager) {
        dispatch_once(&oncePredicate, ^{
            _sharedManager = [[self alloc] init];
        });
    }

    return _sharedManager;
}

- (id)init {
    self = [super init];

    if (self) {
        _adapters = @[
                      [HIDropboxBackup new],
                      [HITimeMachineBackup new],
                    ];
    }

    return self;
}

@end
