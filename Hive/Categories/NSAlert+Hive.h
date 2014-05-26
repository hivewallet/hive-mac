//
//  NSAlert+Hive.h
//  Hive
//
//  Created by Jakub Suder on 26/05/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAlert (Hive)

+ (NSAlert *)hiOKAlertWithTitle:(NSString *)title message:(NSString *)message;
+ (NSAlert *)hiOKAlertWithTitle:(NSString *)title format:(NSString *)format, ... NS_FORMAT_FUNCTION(2,3);

@end
