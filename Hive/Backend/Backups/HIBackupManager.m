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

    dispatch_once(&oncePredicate, ^{
        _sharedManager = [[self alloc] init];
    });

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

- (void)initializeAdapters {
    NSDictionary *settings = [HIBackupAdapter backupSettings];

    for (HIBackupAdapter *adapter in self.adapters) {
        if (![settings objectForKey:adapter.name]) {
            adapter.enabled = [adapter isEnabledByDefault];
        }
    }

    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)performBackups {
    [self.adapters makeObjectsPerformSelector:@selector(performBackup)];
}

@end
