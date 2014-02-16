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

NSString * const HIAddressEntity = @"HIAddress";


@implementation HIAddress

@dynamic address;
@dynamic caption;
@dynamic contact;

- (NSString *)addressWithCaption {
    if (self.caption.length > 0) {
        return [NSString stringWithFormat:@"%@ (%@)", self.caption, self.address];
    } else {
        return self.address;
    }
}

@end
