//
//  HIApplication.m
//  Hive
//
//  Created by Bazyli Zygan on 27.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIApplication.h"
#import "NPZip.h"
#import "BCClient.h"

NSString * const HIApplicationEntity = @"HIApplication";


@implementation HIApplication

@dynamic id;
@dynamic path;
@dynamic name;

- (NSImage *)icon
{
    NSImage *icon = [NSImage imageNamed:@"icon-apps__inactive.pdf"];

    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:self.path.path isDirectory:&isDirectory];

    if (exists && isDirectory)
    {
        NSData *data = [NSData dataWithContentsOfURL:[self.path URLByAppendingPathComponent:@"manifest.json"]];
        NSDictionary *manifest = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];

        if (manifest[@"icon"])
        {
            icon = [[NSImage alloc] initWithContentsOfURL:[self.path URLByAppendingPathComponent:manifest[@"icon"]]];
        }
    }
    else if (exists)
    {
        NPZip *zip = [NPZip archiveWithFile:self.path.path];
        NSData *data = [zip dataForEntryNamed:@"manifest.json"];
        NSDictionary *manifest = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];

        if (manifest[@"icon"])
        {
            icon = [[NSImage alloc] initWithData:[zip dataForEntryNamed:manifest[@"icon"]]];
        }
    }
    
    return icon;
}

@end
