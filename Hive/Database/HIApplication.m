//
//  HIApplication.m
//  Hive
//
//  Created by Bazyli Zygan on 27.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HIApplication.h"
#import "NPZip.h"

NSString * const HIApplicationEntity = @"HIApplication";


@implementation HIApplication

@dynamic id;
@dynamic path;
@dynamic name;

- (NSDictionary *)manifest
{
    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:self.path.path isDirectory:&isDirectory];
    NSData *data;

    if (exists)
    {
        if (isDirectory)
        {
            data = [NSData dataWithContentsOfURL:[self.path URLByAppendingPathComponent:@"manifest.json"]];
        }
        else
        {
            NPZip *zip = [NPZip archiveWithFile:self.path.path];
            data = [zip dataForEntryNamed:@"manifest.json"];
        }
    }

    return data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;
}

- (NSImage *)icon
{
    NSImage *icon = [NSImage imageNamed:@"icon-apps__inactive.pdf"];

    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:self.path.path isDirectory:&isDirectory];

    NSDictionary *manifest = self.manifest;

    if (exists && manifest[@"icon"])
    {
        if (isDirectory)
        {
            icon = [[NSImage alloc] initWithContentsOfURL:[self.path URLByAppendingPathComponent:manifest[@"icon"]]];
        }
        else
        {
            NPZip *zip = [NPZip archiveWithFile:self.path.path];
            icon = [[NSImage alloc] initWithData:[zip dataForEntryNamed:manifest[@"icon"]]];
        }
    }

    return icon;
}

- (void)refreshIcon
{
    [self willChangeValueForKey:@"icon"];
    [self didChangeValueForKey:@"icon"];
}

@end
