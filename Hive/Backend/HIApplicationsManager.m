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
    NPZip *zipFile = [NPZip archiveWithFile:applicationPath.path];
    NSData *JSONfile = [zipFile dataForEntryNamed:@"manifest.json"];

    return [NSJSONSerialization JSONObjectWithData:JSONfile options:0 error:NULL];
}

- (BOOL)hasApplicationOfId:(NSString *)applicationId
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HIApplicationEntity];
    request.predicate = [NSPredicate predicateWithFormat:@"id == %@", applicationId];

    NSUInteger count = [DBM countForFetchRequest:request error:NULL];
    return (count > 0);
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

    app.id = manifest[@"id"];
    app.name = manifest[@"name"];

    NSURL *installedAppURL = [[self applicationsDirectory] URLByAppendingPathComponent:manifest[@"id"]];
    [[NSFileManager defaultManager] removeItemAtURL:installedAppURL error:NULL];
    [[NSFileManager defaultManager] copyItemAtURL:applicationURL toURL:installedAppURL error:NULL];
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
