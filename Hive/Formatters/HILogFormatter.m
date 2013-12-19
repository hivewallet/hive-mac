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

    switch (message->logFlag) {
        case LOG_FLAG_ERROR:
            logLevel = @"ERROR";
            break;
        case LOG_FLAG_WARN:
            logLevel = @"WARN";
            break;
        case LOG_FLAG_INFO:
            logLevel = @"INFO";
            break;
        case LOG_FLAG_DEBUG:
            logLevel = @"DEBUG";
            break;
        case LOG_FLAG_VERBOSE:
            logLevel = @"VERBOSE";
            break;
        default:
            logLevel = @"UNKNOWN";
    }

    NSString *fileName = [[NSString stringWithUTF8String:message->file] lastPathComponent];

    return [NSString stringWithFormat:@"%@ %s (%@:%d)\n%@: %@\n",
            message->timestamp, message->function, fileName, message->lineNumber,
            logLevel, message->logMsg];
}

@end
