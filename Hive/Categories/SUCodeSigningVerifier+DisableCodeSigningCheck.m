//
//  SUCodeSigningVerifier.m
//  Hive
//
//  Created by Jakub Suder on 02.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "SUCodeSigningVerifier+DisableCodeSigningCheck.h"

// this is a hack that disables code signing checking inside Sparkle code - this causes some internal error
// to be created at app startup and is very annoying when you're testing the app inside Xcode with all exceptions
// breakpoint set

@implementation SUCodeSigningVerifier (DisableCodeSigningCheck)

+ (BOOL)hostApplicationIsCodeSigned
{
    return NO;
}

@end
