//
//  HIApplicationsManager.m
//  Hive
//
//  Created by Jakub Suder on 08.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <AFNetworking/AFHTTPRequestOperation.h>
#import "HIAppDelegate.h"
#import "HIApplication.h"
#import "HIApplicationsManager.h"
#import "HIApplicationsViewController.h"
#import "HIDatabaseManager.h"
#import "HIDirectoryDataService.h"
#import "NSAlert+Hive.h"


NSString * const HIApplicationsManagerDomain = @"HIApplicationsManagerDomain";
const NSInteger HIApplicationManagerInvalidAppFileError = -1;
const NSInteger HIApplicationManagerInsecureConnectionError = -2;


@implementation HIApplicationsManager

+ (HIApplicationsManager *)sharedManager {
    static HIApplicationsManager *_sharedManager = nil;
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        _sharedManager = [[self alloc] init];
    });

    return _sharedManager;
}

- (NSDictionary *)applicationMetadata:(NSURL *)applicationPath {
    NSData *data = [[HIDirectoryDataService sharedService] dataForPath:@"manifest.json"
                                                           inDirectory:applicationPath];
    return data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;
}

- (BOOL)hasApplicationOfId:(NSString *)applicationId {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HIApplicationEntity];
    request.predicate = [NSPredicate predicateWithFormat:@"id == %@", applicationId];

    NSUInteger count = [DBM countForFetchRequest:request error:NULL];
    return (count > 0);
}

- (HIApplication *)getApplicationById:(NSString *)applicationId {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HIApplicationEntity];
    request.predicate = [NSPredicate predicateWithFormat:@"id == %@", applicationId];

    return [[DBM executeFetchRequest:request error:NULL] firstObject];
}

- (void)removeApps:(NSArray *)apps {
    for (HIApplication *app in apps) {
        [DBM deleteObject:app];
    }

    NSError *error;
    [DBM save:&error];

    if (error) {
        HILogError(@"Error deleting apps: %@", error);
        return;
    }
}

- (NSArray *)allApps {
    NSError *error = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HIApplicationEntity];
    NSArray *apps = [DBM executeFetchRequest:request error:&error];
    if (error) {
        HILogError(@"Error loading apps: %@", error);
        apps = @[];
    }
    return apps;
}

- (void)rebuildAppsList {
    NSMutableDictionary *knownApps = [NSMutableDictionary new];
    for (HIApplication *app in self.allApps) {
        knownApps[app.id] = app;
    }

    NSArray *apps = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.applicationsDirectory
                                                  includingPropertiesForKeys:nil
                                                                     options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                       error:NULL];

    for (NSURL *appURL in apps) {
        NSString *appName = [appURL lastPathComponent];
        NSDictionary *manifest = [self applicationMetadata:appURL];
        NSString *actualName = manifest[@"id"];

        if ([appName isEqual:actualName]) {
            [self installApplication:appURL];
        } else {
            HILogWarn(@"App name for %@ doesn't match its manifest name (%@)", appURL, actualName);
        }

        [knownApps removeObjectForKey:actualName];
    }

    [self removeApps:[knownApps allValues]];
}

- (void)preinstallApps {
    [self rebuildAppsList];

    // install bundled apps
    NSArray *allApps = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"hiveapp" subdirectory:@""];

    for (NSURL *applicationURL in allApps) {
        [self installApplication:applicationURL];
    }
}

- (HIApplication *)installApplication:(NSURL *)applicationURL {
    NSDictionary *manifest = [self applicationMetadata:applicationURL];
    HIApplication *app = nil;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HIApplicationEntity];
    request.predicate = [NSPredicate predicateWithFormat:@"id == %@", manifest[@"id"]];
    NSArray *response = [DBM executeFetchRequest:request error:NULL];

    if (response.count > 0) {
        app = response[0];
    } else {
        app = [NSEntityDescription insertNewObjectForEntityForName:HIApplicationEntity inManagedObjectContext:DBM];
    }

    NSURL *installedAppURL = [[self applicationsDirectory] URLByAppendingPathComponent:manifest[@"id"]];

    if (![installedAppURL isEqual:applicationURL]) {
        HILogInfo(@"Installing app from %@", applicationURL);

        [[NSFileManager defaultManager] removeItemAtURL:installedAppURL error:NULL];
        [[NSFileManager defaultManager] copyItemAtURL:applicationURL toURL:installedAppURL error:NULL];
    }

    app.id = manifest[@"id"];
    app.name = manifest[@"name"];
    app.path = installedAppURL;

    [app refreshIcon];

    [DBM save:NULL];

    return app;
}

- (void)uninstallApplication:(HIApplication *)application {
    NSError *error = nil;

    [self clearCookiesForApplication:application];

    NSURL *installedAppURL = [[self applicationsDirectory] URLByAppendingPathComponent:application.id];
    [[NSFileManager defaultManager] removeItemAtURL:installedAppURL error:&error];
    if (error) {
        HILogWarn(@"Couldn't delete application %@: %@", application, error);
        return;
    }

    [DBM deleteObject:application];
    [DBM save:&error];
    if (error) {
        HILogWarn(@"Couldn't delete application %@: %@", application, error);
        return;
    }
}

- (BOOL)requestLocalAppInstallation:(NSURL *)applicationURL showAppsPage:(BOOL)showAppsPage error:(NSError **)error {
    NSDictionary *manifest = [self applicationMetadata:applicationURL];
    NSString *title, *info, *confirm;

    if (!manifest[@"id"]) {
        HILogWarn(@"App file at %@ is invalid (manifest: %@)", applicationURL, manifest);

        NSString *title = [NSString stringWithFormat:
                           NSLocalizedString(@"Hive application file \"%@\" could not be opened.",
                                             @"Hiveapp file not readable error title"),
                           applicationURL.lastPathComponent];

        NSString *description = NSLocalizedString(@"The file is damaged or does not contain a Hive application.",
                                                  @"Hiveapp file not readable error details");

        [[NSAlert hiOKAlertWithTitle:title message:description] runModal];

        if (error) {
            *error = [NSError errorWithDomain:HIApplicationsManagerDomain
                                         code:HIApplicationManagerInvalidAppFileError
                                     userInfo:@{NSLocalizedFailureReasonErrorKey: description}];
        }

        return NO;
    }

    if ([self hasApplicationOfId:manifest[@"id"]]) {
        title = NSLocalizedString(@"You have already added \"%@\" to Hive. Would you like to overwrite it?",
                                  @"Install app popup title when app exists");

        info = NSLocalizedString(@"The existing app file will be replaced by the new version. "
                                 @"This will not affect any app settings or saved data.",
                                 @"Install app popup warning message when app exists");

        confirm = NSLocalizedString(@"Reinstall", @"Install app button title when app exists");
    } else {
        title = NSLocalizedString(@"Do you want to add \"%@\" to Hive?",
                                  @"Install app popup title");

        info = NSLocalizedString(@"We cannot guarantee the safety of all apps - please be careful "
                                 @"if you download Hive apps from third party sites.",
                                 @"Install app popup warning message");

        confirm = NSLocalizedString(@"Install", @"Install app button title");
    }

    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:title, manifest[@"name"]]
                                     defaultButton:confirm
                                   alternateButton:NSLocalizedString(@"Cancel", nil)
                                       otherButton:nil
                         informativeTextWithFormat:@"%@", info];

    if ([alert runModal] == NSAlertDefaultReturn) {
        [self installApplication:applicationURL];

        if (showAppsPage) {
            [[NSApp delegate] showWindowWithPanel:[HIApplicationsViewController class]];
        }

        return YES;
    } else {
        return NO;
    }
}

- (void)requestRemoteAppInstallation:(NSURL *)remoteURL onCompletion:(void (^)(BOOL, NSError *))completionBlock {
    HILogInfo(@"Downloading remote app from %@", remoteURL);

    NSError *error = nil;
    if (![self validateRemoteAppURL:remoteURL error:&error]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(NO, error);
        });

        return;
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:remoteURL];
    AFHTTPRequestOperation *download = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    NSString *temporaryFile = [NSTemporaryDirectory() stringByAppendingPathComponent:remoteURL.lastPathComponent];
    [download setOutputStream:[NSOutputStream outputStreamToFileAtPath:temporaryFile append:NO]];

    [download setRedirectResponseBlock:
     ^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *response) {
         NSError *error = nil;

         if ([self validateRemoteAppURL:request.URL error:&error]) {
             return request;
         } else {
             [connection cancel];
             completionBlock(NO, error);
             return nil;
         }
     }];

    [download setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        HILogInfo(@"App downloaded to: %@", temporaryFile);

        NSError *error = nil;
        BOOL installed = [self requestLocalAppInstallation:[NSURL fileURLWithPath:temporaryFile]
                                              showAppsPage:NO
                                                     error:&error];
        [self cleanupTemporaryFileAtPath:temporaryFile];

        completionBlock(installed, error);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        HILogWarn(@"Couldn't download remote app: %@", error);
        [self cleanupTemporaryFileAtPath:temporaryFile];

        completionBlock(NO, error);
    }];

    [download start];
}

- (BOOL)requestApplicationRemoval:(HIApplication *)application {
    NSString *title = NSLocalizedString(@"Do you want to remove \"%@\" from the application list?",
                                        @"Uninstall app popup title");

    NSString *info = NSLocalizedString(@"You can install it again through the App Store app later "
                                       @"if you change your mind.",
                                       @"Uninstall app popup message");

    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:title, application.name]
                                     defaultButton:NSLocalizedString(@"Uninstall", @"Uninstall app button title")
                                   alternateButton:NSLocalizedString(@"Cancel", nil)
                                       otherButton:nil
                         informativeTextWithFormat:@"%@", info];

    if ([alert runModal] == NSAlertDefaultReturn) {
        [self uninstallApplication:application];

        return YES;
    } else {
        return NO;
    }
}

- (BOOL)validateRemoteAppURL:(NSURL *)remoteURL error:(NSError **)error {
    if (![remoteURL.scheme isEqual:@"https"]) {
        HILogWarn(@"App request rejected because of insecure connection: %@", remoteURL);

        if (error) {
            NSString *message = @"Applications can only be downloaded from HTTPS URLs.";
            *error = [NSError errorWithDomain:HIApplicationsManagerDomain
                                         code:HIApplicationManagerInsecureConnectionError
                                     userInfo:@{ NSLocalizedFailureReasonErrorKey: message }];
        }

        return NO;
    }

    return YES;
}

- (void)cleanupTemporaryFileAtPath:(NSString *)path {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}

- (NSUInteger)clearCookiesForApplication:(HIApplication *)application {
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSUInteger count = 0;

    for (NSHTTPCookie *cookie in [storage cookiesForURL:application.baseURL]) {
        [storage deleteCookie:cookie];
        count++;
    }

    return count;
}

- (NSUInteger)clearAllApplicationCookies {
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSUInteger count = 0;

    for (NSHTTPCookie *cookie in storage.cookies) {
        if ([cookie.domain hasSuffix:@".hiveapp"]) {
            [storage deleteCookie:cookie];
            count++;
        }
    }

    return count;
}

- (NSURL *)applicationsDirectory {
    NSURL *appSupportURL = [(HIAppDelegate *) [NSApp delegate] applicationFilesDirectory];
    NSURL *applicationsURL = [appSupportURL URLByAppendingPathComponent:@"Applications"];

    [[NSFileManager defaultManager] createDirectoryAtURL:applicationsURL
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:NULL];

    return applicationsURL;
}

@end
