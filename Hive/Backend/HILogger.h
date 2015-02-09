//
//  HILogger.h
//  BitcoinKit
//
//  Created by Jakub Suder on 17.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

typedef NS_ENUM(int, HILoggerLevel) {
    HILoggerLevelDebug = 1,
    HILoggerLevelInfo = 2,
    HILoggerLevelWarn = 3,
    HILoggerLevelError = 4,
};

extern void HILoggerLog(const char *fileName, const char *functionName, int lineNumber,
                        HILoggerLevel level, NSString *message, ...) NS_FORMAT_FUNCTION(5, 6);

#define HILogError(...)   HILoggerLog(__FILE__, __FUNCTION__, __LINE__, HILoggerLevelError, __VA_ARGS__)
#define HILogWarn(...)    HILoggerLog(__FILE__, __FUNCTION__, __LINE__, HILoggerLevelWarn, __VA_ARGS__)
#define HILogInfo(...)    HILoggerLog(__FILE__, __FUNCTION__, __LINE__, HILoggerLevelInfo, __VA_ARGS__)
#define HILogDebug(...)   HILoggerLog(__FILE__, __FUNCTION__, __LINE__, HILoggerLevelDebug, __VA_ARGS__)


@interface HILogger : NSObject

@property (strong) void (^logHandler)(const char *fileName, const char *functionName, int lineNumber,
                                      HILoggerLevel level, NSString *message);

+ (instancetype)sharedLogger;

@end
