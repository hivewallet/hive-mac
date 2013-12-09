//
//  HIErrorWindowController.m
//  Hive
//
//  Created by Jakub Suder on 30.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <HockeySDK/HockeySDK.h>
#import "HIErrorWindowController.h"

@interface BITCrashManager (Private)

- (NSString *)userName;
- (NSString *)userEmail;
- (NSString *)loadSettings;
- (BOOL)addStringValueToKeychain:(NSString *)stringValue forKey:(NSString *)key;

@end

@interface HIErrorWindowController () {
    NSException *_exception;
}

@end

@implementation HIErrorWindowController

- (id)initWithException:(NSException *)exception {
    self = [super initWithWindowNibName:@"HIErrorWindowController"];

    if (self) {
        _exception = exception;
    }

    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];

    BITCrashManager *crashManager = [[BITHockeyManager sharedHockeyManager] crashManager];
    [crashManager loadSettings];

    if (crashManager.userName) {
        self.nameField.stringValue = crashManager.userName;
    }

    if (crashManager.userEmail) {
        self.emailField.stringValue = crashManager.userEmail;
    }

    NSMutableString *info = [NSMutableString stringWithFormat:@"%@\n", _exception.reason];

    NSString *javaStackTrace = _exception.userInfo[@"stackTrace"];
    if (javaStackTrace) {
        [info appendFormat:@"\nJava stack trace:\n\n%@", javaStackTrace];
    }

    if (_exception.callStackSymbols) {
        [info appendFormat:@"\nCocoa stack trace:\n\n%@", _exception.callStackSymbols];
    }

    self.exceptionDetails.string = info;
    self.exceptionDetails.textColor = [NSColor colorWithCalibratedWhite:0.33 alpha:1.0];
}

- (IBAction)cancelReport:(id)sender {
    [self close];
}

- (IBAction)sendReport:(id)sender {
    NSDictionary *appInfo = [[NSBundle mainBundle] infoDictionary];
    NSDictionary *systemVersionInfo = [NSDictionary dictionaryWithContentsOfFile:
                                       @"/System/Library/CoreServices/SystemVersion.plist"];

    NSString *userName = self.nameField.stringValue;
    NSString *userEmail = self.emailField.stringValue;

    BITCrashManager *crashManager = [[BITHockeyManager sharedHockeyManager] crashManager];

    if (userName) {
        [crashManager addStringValueToKeychain:userName forKey:@"default.BITCrashMetaUserName"];
    }

    if (userEmail) {
        [crashManager addStringValueToKeychain:userEmail forKey:@"default.BITCrashMetaUserEmail"];
    }

    NSString *description = [NSString stringWithFormat:@"%@\n\nLog:\n%@\n\n%@",
                             self.comments.string,
                             _exception.reason,
                             _exception.userInfo[@"stackTrace"]];

    description = [description stringByReplacingOccurrencesOfString:@"]]>"
                                                         withString:@"]]" @"]]><![CDATA[" @">"
                                                            options:NSLiteralSearch
                                                              range:NSMakeRange(0, description.length)];

    NSString *crashLogString = [NSString stringWithFormat:
                                @"Application Specific Information:\n"
                                @"*** Terminating app due to uncaught exception '%@', reason: '%@'\n\n"
                                @"Last Exception Backtrace:\n"
                                @"%@",
                                _exception.name,
                                _exception.reason,
                                [_exception.callStackSymbols componentsJoinedByString:@"\n"]];

    NSString *xml = [NSString stringWithFormat:
                     @"<crashes><crash>"
                     @"<applicationname>%@</applicationname>"
                     @"<uuids>%@</uuids>"
                     @"<bundleidentifier>%@</bundleidentifier>"
                     @"<systemversion>%@</systemversion>"
                     @"<senderversion>%@</senderversion>"
                     @"<version>%@</version>"
                     @"<uuid>%@</uuid>"
                     @"<platform>%@</platform>"
                     @"<userid>%@</userid>"
                     @"<contact>%@</contact>"
                     @"<description><![CDATA[%@]]></description>"
                     @"<log><![CDATA[%@]]></log>"
                     @"</crash></crashes>",
                     appInfo[@"CFBundleExecutable"],
                     @"",
                     appInfo[@"CFBundleIdentifier"],
                     systemVersionInfo[@"ProductVersion"],
                     appInfo[@"CFBundleVersion"],
                     appInfo[@"CFBundleVersion"],
                     @"",
                     [BITSystemProfile deviceModel],
                     userName,
                     userEmail,
                     description,
                     crashLogString];

    [[[BITHockeyManager sharedHockeyManager] crashManager] performSelector:@selector(postXML:) withObject:xml];

    [self close];
}

@end
