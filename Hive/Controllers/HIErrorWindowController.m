//
//  HIErrorWindowController.m
//  Hive
//
//  Created by Jakub Suder on 30.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIErrorWindowController.h"

@interface HIErrorWindowController ()
{
    NSException *_exception;
}

@end

@implementation HIErrorWindowController

- (id)initWithException:(NSException *)exception
{
    self = [super initWithWindowNibName:@"HIErrorWindowController"];

    if (self)
    {
        _exception = exception;
    }

    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    NSMutableString *info = [NSMutableString stringWithFormat:@"%@\n", _exception.reason];

    NSString *javaStackTrace = _exception.userInfo[@"stackTrace"];
    if (javaStackTrace)
    {
        [info appendFormat:@"\nJava stack trace:\n\n%@", javaStackTrace];
    }

    if (_exception.callStackSymbols)
    {
        [info appendFormat:@"\nCocoa stack trace:\n\n%@", _exception.callStackSymbols];
    }

    self.textView.string = info;
}

@end
