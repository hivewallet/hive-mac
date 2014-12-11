//
//  HILogFileManager.m
//  Hive
//
//  Created by Jakub Suder on 11/12/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HILogFileManager.h"

@implementation HILogFileManager

- (NSString *)applicationName {
    if (DEBUG_OPTION_ENABLED(TESTING_NETWORK)) {
        return @"HiveTest";
    } else {
        return @"Hive";
    }
}

@end
