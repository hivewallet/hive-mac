//
//  HIApplication.m
//  Hive
//
//  Created by Bazyli Zygan on 27.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIApplication.h"

#import "HIDirectoryDataService.h"

NSString * const HIApplicationEntity = @"HIApplication";


@implementation HIApplication

@dynamic id;
@dynamic path;
@dynamic name;

- (NSDictionary *)manifest {
    NSData *data = [[HIDirectoryDataService sharedService] dataForPath:@"manifest.json"
                                                           inDirectory:self.path];
    return data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;
}

- (NSImage *)icon {
    NSDictionary *manifest = self.manifest;
    NSString *icon = manifest[@"icon"];
    if (icon) {
        NSData *data = [[HIDirectoryDataService sharedService] dataForPath:icon
                                                               inDirectory:self.path];
        if (data) {
            return [[NSImage alloc] initWithData:data];
        }
    }
    return [NSImage imageNamed:@"icon-unknown-app"];
}

- (void)refreshIcon {
    [self willChangeValueForKey:@"icon"];
    [self didChangeValueForKey:@"icon"];
}

@end
