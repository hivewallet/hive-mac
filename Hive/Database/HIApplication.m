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
    BOOL dir;
    NSImage *ic = nil;
    [[NSFileManager defaultManager] fileExistsAtPath:self.path.path isDirectory:&dir];
    NSDictionary *manifest = nil;
    if (dir)
    {
        manifest = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:[self.path URLByAppendingPathComponent:@"manifest.json"]] options:0 error:NULL];
        if (manifest[@"icon"])
        {
            ic = [[NSImage alloc] initWithContentsOfURL:[self.path URLByAppendingPathComponent:manifest[@"icon"]]];
        }
    }
    else
    {
        NPZip *zip = [NPZip archiveWithFile:self.path.path];
        manifest = [NSJSONSerialization JSONObjectWithData:[zip dataForEntryNamed:@"manifest.json"] options:0 error:NULL];
        if (manifest[@"icon"])
        {
            ic = [[NSImage alloc] initWithData:[zip dataForEntryNamed:manifest[@"icon"]]];
        }
    }
    
    return ic;
}
@end
