//
//  HIApplicationURLProtocol.h
//  Hive
//
//  Created by Bazyli Zygan on 18.07.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

/*
 Used for loading application files from the app bundle in user's Application Support folder.
 */

@interface HIApplicationURLProtocol : NSURLProtocol <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@end
