//
//  HIApplicationURLProtocol.m
//  Hive
//
//  Created by Bazyli Zygan on 18.07.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIApplicationsManager.h"
#import "HIApplicationURLProtocol.h"
#import "HIDirectoryDataService.h"

@implementation HIApplicationURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [request.URL.host hasSuffix:@".hiveapp"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSArray *pathComponents = self.request.URL.pathComponents;
    NSString *appName = [self.request.URL.host substringToIndex:(self.request.URL.host.length - 8)];
    NSArray *localPathComponents = [pathComponents subarrayWithRange:NSMakeRange(1, pathComponents.count - 1)];
    NSString *localPath = [NSString pathWithComponents:localPathComponents];

    NSURL *applicationsDirectory = [[HIApplicationsManager sharedManager] applicationsDirectory];
    NSURL *applicationURL = [applicationsDirectory URLByAppendingPathComponent:appName];


    NSData *contentData = [[HIDirectoryDataService sharedService] dataForPath:localPath
                                                                  inDirectory:applicationURL];

    if (!contentData) {
        [self.client URLProtocol:self
                  didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil]];
    } else {
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                  statusCode:200
                                                                 HTTPVersion:@"1.1"
                                                                headerFields:nil];

        [self.client URLProtocol:self
              didReceiveResponse:response
              cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];

        [self.client URLProtocol:self didLoadData:contentData];
        [self.client URLProtocolDidFinishLoading:self];
    }
}

- (void)stopLoading {
}

@end
