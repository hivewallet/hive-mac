//
//  HIApplicationsManager.h
//  Hive
//
//  Created by Jakub Suder on 08.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HIApplication;

extern NSString * const HIApplicationsManagerDomain;
extern const NSInteger HIApplicationManagerInvalidAppFileError;

/*
 Manages applications (HIApplication) in the database and on disk.
 */

@interface HIApplicationsManager : NSObject

+ (HIApplicationsManager *)sharedManager;

- (NSURL *)applicationsDirectory;
- (HIApplication *)installApplication:(NSURL *)applicationURL;
- (BOOL)requestLocalAppInstallation:(NSURL *)applicationURL showAppsPage:(BOOL)showAppsPage error:(NSError **)error;
- (void)requestRemoteAppInstallation:(NSURL *)remoteURL onCompletion:(void (^)(BOOL, NSError *))completionBlock;
- (BOOL)hasApplicationOfId:(NSString *)applicationId;
- (HIApplication *)getApplicationById:(NSString *)applicationId;
- (NSDictionary *)applicationMetadata:(NSURL *)applicationPath;
- (void)preinstallApps;
- (void)rebuildAppsList;

@end
