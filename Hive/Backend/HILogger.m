//
//  HILogger.m
//  BitcoinKit
//
//  Created by Jakub Suder on 17.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HILogger.h"

void HILoggerLog(const char *fileName, const char *functionName, int lineNumber,
                 HILoggerLevel level, NSString *message, ...) {
    va_list args;
    va_start(args, message);
    NSString *logText = [[NSString alloc] initWithFormat:message arguments:args];
    va_end(args);

    HILogger *logger = [HILogger sharedLogger];
    logger.logHandler(fileName, functionName, lineNumber, level, logText);
}

@implementation HILogger

+ (HILogger *)sharedLogger {
    static HILogger *sharedLogger = nil;
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        sharedLogger = [[self alloc] init];
        sharedLogger.logHandler = ^(const char *fileName, const char *functionName, int lineNumber,
                                    HILoggerLevel level, NSString *message) {
            NSLog(@"%@", message);
        };
    });

    return sharedLogger;
}

@end
