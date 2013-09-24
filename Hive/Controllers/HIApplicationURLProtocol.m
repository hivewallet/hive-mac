//
//  HIApplicationURLProtocol.m
//  Hive
//
//  Created by Bazyli Zygan on 18.07.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIApplicationURLProtocol.h"
#import "BCClient.h"
#import "NPZip.h"

static NPZip *f_zip = nil;

@interface HIApplicationURLProtocol ()
{
    NSURLConnection *_conn;
}

@end

@implementation HIApplicationURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    // only handle http requests we haven't marked with our header.
    if ([[[request URL] scheme] isEqualToString:@"http"] || [[[request URL] scheme] isEqualToString:@"https"])
    {
        if (request.allHTTPHeaderFields[@"HIApplicationURLProtocolHandled"])
            return NO;
        
        return YES;
    }
    
    
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

+ (BOOL)URLisZipped:(NSURL *)request
{
    if ([[request pathComponents] count] < 2)
        return NO;
    
    // We need to check if that "file" isn't the zip file
    NSURL *appURL = [[[BCClient sharedClient] applicationsDirectory] URLByAppendingPathComponent:[request pathComponents][1]];
    BOOL dir = YES;
    if ([[NSFileManager defaultManager] fileExistsAtPath:appURL.path isDirectory:&dir])
    {
        if (!dir)
            return YES;
    }
    
    return NO;
}

- (void)startLoading
{
    if (![HIApplicationURLProtocol URLisZipped:self.request.URL])
    {
        NSMutableURLRequest *req = [self.request mutableCopy];
        [req setValue:@"YES" forHTTPHeaderField:@"HIApplicationURLProtocolHandled"];
//        NSLog(@"Starting downloading %@", self.request.URL);
        _conn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES];
         
        return;
    }
    if (!f_zip || [f_zip.name compare:self.request.URL.host] != NSOrderedSame)
    {
        NSURL *appURL = [[[BCClient sharedClient] applicationsDirectory] URLByAppendingPathComponent:[self.request.URL pathComponents][1]];
        f_zip = [NPZip archiveWithFile:appURL.path];
    }
    NSMutableArray *cs = [[self.request.URL pathComponents] mutableCopy];
    [cs removeObjectAtIndex:0];
    [cs removeObjectAtIndex:0];
    NSData *contentData = [f_zip dataForEntryNamed:[NSString pathWithComponents:cs]];
    
    if (!contentData)
    {
        [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil]];
    }
    else
    {
        [[self client] URLProtocol:self didReceiveResponse:[[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                                       statusCode:200 HTTPVersion:@"1.1"
                                                                                     headerFields:@{@"Access-Control-Allow-Origin" : @"*",
                                                                                                    @"Access-Control-Allow-Headers" : @"*"}]
                cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];
        [[self client] URLProtocol:self didLoadData:contentData];
        [[self client] URLProtocolDidFinishLoading:self];
    }
}

- (void)stopLoading
{
    [_conn cancel];
    _conn = nil;
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil]];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
    
    NSMutableDictionary *respHeaders = [resp.allHeaderFields mutableCopy];
    [respHeaders setObject:@"*" forKey:@"Access-Control-Allow-Origin"];
    [respHeaders setObject:@"*" forKey:@"Access-Control-Allow-Headers"];
    [[self client] URLProtocol:self didReceiveResponse:[[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                                   statusCode:resp.statusCode HTTPVersion:@"1.1"
                                                                                 headerFields:respHeaders]
            cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [[self client] URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[self client] URLProtocolDidFinishLoading:self];    
}

//- (void)connectionDidFinishDownloading:(NSURLConnection *)connection destinationURL:(NSURL *)destinationURL
//{
//    [self connectionDidFinishLoading:connection];
//}
@end
