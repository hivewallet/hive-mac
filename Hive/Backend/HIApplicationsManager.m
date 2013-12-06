//
//  HIApplicationsManager.m
//  Hive
//
//  Created by Jakub Suder on 08.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIApplication.h"
#import "HIApplicationsManager.h"
#import "NPZip.h"

@implementation HIApplicationsManager

+ (HIApplicationsManager *)sharedManager
{
    static HIApplicationsManager *_sharedManager = nil;
    static dispatch_once_t oncePredicate;

    if (!_sharedManager)
    {
        dispatch_once(&oncePredicate, ^{
            _sharedManager = [[self alloc] init];
        });
    }

    return _sharedManager;
}

- (NSDictionary *)applicationMetadata:(NSURL *)applicationPath
{
    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:applicationPath.path isDirectory:&isDirectory];

    NSData *data;

    if (exists)
    {
        if (isDirectory)
        {
            data = [NSData dataWithContentsOfURL:[applicationPath URLByAppendingPathComponent:@"manifest.json"]];
        }
        else
        {
            NPZip *zipFile = [NPZip archiveWithFile:applicationPath.path];
            data = [zipFile dataForEntryNamed:@"manifest.json"];
        }
    }

    return data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;
}

- (BOOL)hasApplicationOfId:(NSString *)applicationId
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HIApplicationEntity];
    request.predicate = [NSPredicate predicateWithFormat:@"id == %@", applicationId];

    NSUInteger count = [DBM countForFetchRequest:request error:NULL];
    return (count > 0);
}

- (void)removeAllApps
{
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HIApplicationEntity];
    NSArray *apps = [DBM executeFetchRequest:request error:&error];

    if (error)
    {
        NSLog(@"%@: Error loading apps: %@", NSStringFromSelector(_cmd), error);
        return;
    }

    for (HIApplication *app in apps)
    {
        [DBM deleteObject:app];
    }

    [DBM save:&error];

    if (error)
    {
        NSLog(@"%@: Error deleting apps: %@", NSStringFromSelector(_cmd), error);
        return;
    }
}

- (void)rebuildAppsList
{
    [self removeAllApps];

    NSArray *apps = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.applicationsDirectory
                                                  includingPropertiesForKeys:nil
                                                                     options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                       error:NULL];

    for (NSURL *appURL in apps)
    {
        NSString *appName = [appURL lastPathComponent];
        NSDictionary *manifest = [self applicationMetadata:appURL];
        NSString *actualName = manifest[@"id"];

        if ([appName isEqual:actualName])
        {
            [self installApplication:appURL];
        }
        else
        {
            NSLog(@"App name for %@ doesn't match its manifest name (%@)", appURL, actualName);
        }
    }
}

- (void)preinstallApps
{
    NSArray *allApps = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"hiveapp" subdirectory:@""];

    for (NSURL *applicationURL in allApps)
    {
        [self installApplication:applicationURL];
    }
}

- (void)installApplication:(NSURL *)applicationURL
{
    NSDictionary *manifest = [self applicationMetadata:applicationURL];
    HIApplication *app = nil;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HIApplicationEntity];
    request.predicate = [NSPredicate predicateWithFormat:@"id == %@", manifest[@"id"]];
    NSArray *response = [DBM executeFetchRequest:request error:NULL];

    if (response.count > 0)
    {
        app = response[0];
    }
    else
    {
        app = [NSEntityDescription insertNewObjectForEntityForName:HIApplicationEntity inManagedObjectContext:DBM];
    }

    NSURL *installedAppURL = [[self applicationsDirectory] URLByAppendingPathComponent:manifest[@"id"]];

    if (![installedAppURL isEqual:applicationURL])
    {
        [[NSFileManager defaultManager] removeItemAtURL:installedAppURL error:NULL];
        [[NSFileManager defaultManager] copyItemAtURL:applicationURL toURL:installedAppURL error:NULL];
    }

    app.id = manifest[@"id"];
    app.name = manifest[@"name"];
    app.path = installedAppURL;

    [app refreshIcon];

    [DBM save:NULL];
}

- (NSURL *)applicationsDirectory
{
    NSURL *appSupportURL = [(HIAppDelegate *) [NSApp delegate] applicationFilesDirectory];
    NSURL *applicationsURL = [appSupportURL URLByAppendingPathComponent:@"Applications"];

    [[NSFileManager defaultManager] createDirectoryAtURL:applicationsURL
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:NULL];

    return applicationsURL;
}

@end
