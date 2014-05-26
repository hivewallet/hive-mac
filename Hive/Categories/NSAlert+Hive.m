//
//  NSAlert+Hive.m
//  Hive
//
//  Created by Jakub Suder on 26/05/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "NSAlert+Hive.h"

@implementation NSAlert (Hive)

+ (NSAlert *)hiOKAlertWithTitle:(NSString *)title format:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    return [NSAlert alertWithMessageText:title
                           defaultButton:NSLocalizedString(@"OK", @"OK button title")
                         alternateButton:nil
                             otherButton:nil
               informativeTextWithFormat:@"%@", message];
}

+ (NSAlert *)hiOKAlertWithTitle:(NSString *)title message:(NSString *)message {
    return [self hiOKAlertWithTitle:title format:@"%@", message];
}

@end
