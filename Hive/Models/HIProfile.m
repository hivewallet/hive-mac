//
//  HIProfile.m
//  Hive
//
//  Created by Jakub Suder on 02.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HIProfile.h"

@implementation HIProfileAddress

@end

@implementation HIProfile

- (NSDictionary *)profileData {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"Profile"];
}

- (void)updateField:(NSString *)key withValue:(id)value {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *data = [[defaults objectForKey:@"Profile"] mutableCopy];

    if (value) {
        data[key] = value;
    } else {
        [data removeObjectForKey:key];
    }

    [defaults setObject:data forKey:@"Profile"];
    [defaults synchronize];
}

- (NSString *)firstname {
    return [self profileData][@"firstname"];
}

- (void)setFirstname:(NSString *)firstname {
    [self updateField:@"firstname" withValue:firstname];
}

- (NSString *)lastname {
    return [self profileData][@"lastname"];
}

- (void)setLastname:(NSString *)lastname {
    [self updateField:@"lastname" withValue:lastname];
}

- (NSString *)email {
    return [self profileData][@"email"];
}

- (void)setEmail:(NSString *)email {
    [self updateField:@"email" withValue:email];
}

- (NSString *)name {
    NSString *first = self.firstname;
    NSString *last = self.lastname;

    if (first || last) {
        return [NSString stringWithFormat:@"%@ %@", first ?: @"", last ?: @""];
    } else {
        return NSLocalizedString(@"Anonymous", @"Anonymous username for profile page");
    }
}

- (NSSet *)addresses {
    HIProfileAddress *address = [[HIProfileAddress alloc] init];
    address.address = [[BCClient sharedClient] walletHash];
    address.caption = NSLocalizedString(@"main", @"Main address caption");
    address.contact = self;

    return [NSSet setWithObject:address];
}

- (NSImage *)avatarImage {
    if (self.avatar) {
        return [[NSImage alloc] initWithData:self.avatar];
    } else {
        return [NSImage imageNamed:@"avatar-empty"];
    }
}

- (NSData *)avatar {
    return [self profileData][@"avatar"];
}

- (void)setAvatar:(NSData *)avatar {
    [self updateField:@"avatar" withValue:avatar];
}


- (BOOL)canBeRemoved {
    return NO;
}

- (BOOL)canEditAddresses {
    return NO;
}

@end
