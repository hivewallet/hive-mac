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

@interface HIApplicationURLProtocol ()
{
    NSURLConnection *_conn;
}

@end

@implementation HIApplicationURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    // only handle http requests we haven't marked with our header.
    if ([request.URL.scheme isEqualToString:@"http"] || [request.URL.scheme isEqualToString:@"https"])
    {
        if (request.allHTTPHeaderFields[@"HIApplicationURLProtocolHandled"])
        {
            return NO;
        }
        
        return YES;
    }
    
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (BOOL)isURLZipped:(NSURL *)URL
{
    if (URL.pathComponents.count < 2)
    {
        return NO;
    }

    NSString *appName = URL.pathComponents[1];
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
    if (![self isURLZipped:self.request.URL])
    {
        NSMutableURLRequest *req = [self.request mutableCopy];
        [req setValue:@"YES" forHTTPHeaderField:@"HIApplicationURLProtocolHandled"];
        _conn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES];
         
        return;
    }

    if (!zipFile || ![zipFile.name isEqual:self.request.URL.host])
    {
        NSURL *applicationsDirectory = [[HIApplicationsManager sharedManager] applicationsDirectory];
        NSURL *applicationURL = [applicationsDirectory URLByAppendingPathComponent:self.request.URL.pathComponents[1]];
        zipFile = [NPZip archiveWithFile:applicationURL.path];
    }

    NSMutableArray *cs = [self.request.URL.pathComponents mutableCopy];
    [cs removeObjectAtIndex:0];
    [cs removeObjectAtIndex:0];

    NSData *contentData = [zipFile dataForEntryNamed:[NSString pathWithComponents:cs]];
    
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
    [_conn cancel];
    _conn = nil;
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.client URLProtocol:self
            didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil]];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;

    NSMutableDictionary *respHeaders = [resp.allHeaderFields mutableCopy];
    [respHeaders setObject:@"*" forKey:@"Access-Control-Allow-Origin"];
    [respHeaders setObject:@"*" forKey:@"Access-Control-Allow-Headers"];

    NSHTTPURLResponse *returnedResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                      statusCode:resp.statusCode
                                                                     HTTPVersion:@"1.1"
                                                                    headerFields:respHeaders];

    [self.client URLProtocol:self
          didReceiveResponse:returnedResponse
          cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self.client URLProtocolDidFinishLoading:self];
}

@end
