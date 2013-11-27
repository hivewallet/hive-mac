//
//  HIApplicationURLProtocol.m
//  Hive
//
//  Created by Bazyli Zygan on 18.07.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIApplicationsManager.h"
#import "HIApplicationURLProtocol.h"
#import "NPZip.h"

static NPZip *zipFile = nil;


@implementation HIApplicationURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    return [request.URL.host hasSuffix:@".hiveapp"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (BOOL)isURLZipped:(NSURL *)URL
{
    NSString *appName = [URL.host substringToIndex:(URL.host.length - 8)];
    NSURL *applicationsDirectory = [[HIApplicationsManager sharedManager] applicationsDirectory];
    NSURL *applicationURL = [applicationsDirectory URLByAppendingPathComponent:appName];

    BOOL dir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:applicationURL.path isDirectory:&dir])
    {
        if (!dir)
        {
            return YES;
        }
    }
    
    return NO;
}

- (void)startLoading
{
    NSData *contentData;

    NSArray *pathComponents = self.request.URL.pathComponents;
    NSString *appName = [self.request.URL.host substringToIndex:(self.request.URL.host.length - 8)];
    NSArray *localPathComponents = [pathComponents subarrayWithRange:NSMakeRange(1, pathComponents.count - 1)];
    NSString *localPath = [NSString pathWithComponents:localPathComponents];

    NSURL *applicationsDirectory = [[HIApplicationsManager sharedManager] applicationsDirectory];
    NSURL *applicationURL = [applicationsDirectory URLByAppendingPathComponent:appName];

    if ([self isURLZipped:self.request.URL])
    {
        if (!zipFile || ![zipFile.name isEqual:appName])
        {
            zipFile = [NPZip archiveWithFile:applicationURL.path];
        }

        contentData = [zipFile dataForEntryNamed:localPath];
    }
    else
    {
        contentData = [NSData dataWithContentsOfURL:[applicationURL URLByAppendingPathComponent:localPath]];
    }

    if (!contentData)
    {
        [self.client URLProtocol:self
                  didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil]];
    }
    else
    {
        NSDictionary *headers = @{
                                  @"Access-Control-Allow-Origin": @"*",
                                  @"Access-Control-Allow-Headers" : @"*"
                                };

        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                  statusCode:200
                                                                 HTTPVersion:@"1.1"
                                                                headerFields:headers];

        [self.client URLProtocol:self
              didReceiveResponse:response
              cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];

        [self.client URLProtocol:self didLoadData:contentData];
        [self.client URLProtocolDidFinishLoading:self];
    }
}

- (void)stopLoading
{
}

@end
