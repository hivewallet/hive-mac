//
//  HISecureAppStorage.h
//  Hive
//
//  Created by Jakub Suder on 20.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIJavaScriptObject.h"

@class HIApplication;

/*
 Implements a secure version of cookies/localStorage, stored in a keychain, which can be used to store access tokens.
 */

@interface HISecureAppStorage : HIJavaScriptObject

- (id)initWithApplication:(HIApplication *)application frame:(WebFrame *)frame;

@end
