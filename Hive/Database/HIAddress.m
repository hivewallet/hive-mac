//
//  HIAddress.m
//  Hive
//
//  Created by Bazyli Zygan on 06.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIAddress.h"
#import "HIContact.h"

static const NSInteger SuffixLength = 8;

@implementation HIAddress

@dynamic address;
@dynamic caption;
@dynamic contact;

+ (NSString *)truncateAddress:(NSString *)address
{
    if (address.length <= SuffixLength)
    {
        return [address copy];
    }
    else
    {
        NSString *suffix = [address substringFromIndex:(address.length - SuffixLength)];
        return [NSString stringWithFormat:@"…%@", suffix];
    }
}

- (NSString*)addressSuffix
{
    return [HIAddress truncateAddress:self.address];
}

- (NSString *)addressSuffixWithCaption
{
    return [NSString stringWithFormat:@"%@ (%@)", self.caption, self.addressSuffix];
}

@end
