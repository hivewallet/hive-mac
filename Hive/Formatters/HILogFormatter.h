//
//  HILogFormatter.h
//  Hive
//
//  Created by Jakub Suder on 18.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <CocoaLumberjack/DDLog.h>

/*
 Implementation of a CocoaLumberjack log formatter used for formatting log entries for the file in ~/Library/Logs
 and the Xcode debugging window.
 */

@interface HILogFormatter : NSObject <DDLogFormatter>

@end
