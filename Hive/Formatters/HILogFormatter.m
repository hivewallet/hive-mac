//
//  HILogFormatter.m
//  Hive
//
//  Created by Jakub Suder on 18.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HILogFormatter.h"

@implementation HILogFormatter

- (NSString *)formatLogMessage:(DDLogMessage *)message {
    NSString *logLevel;

    switch (message->_flag) {
        case DDLogFlagError:
            logLevel = @"ERROR";
            break;
        case DDLogFlagWarning:
            logLevel = @"WARN";
            break;
        case DDLogFlagInfo:
            logLevel = @"INFO";
            break;
        case DDLogFlagDebug:
            logLevel = @"DEBUG";
            break;
        case DDLogFlagVerbose:
            logLevel = @"VERBOSE";
            break;
        default:
            logLevel = @"UNKNOWN";
    }

    return [NSString stringWithFormat:@"%@ %@ (%@:%lu)\n%@: %@\n",
            message->_timestamp,
            message->_function,
            [message->_file lastPathComponent],
            message->_line,
            logLevel,
            message->_message];
}

@end
