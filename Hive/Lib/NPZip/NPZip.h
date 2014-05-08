//
//  NPZip.h
//  ZipTest
//
//  Created by Bazyli Zygan on 23.11.2011.
//  Copyright (c) 2011 Hive Developers. All rights reserved.
//

#import "NPZipHeader.h"

@interface NPZip : NSObject {
	NSString *__file;
	
	NPZipHeader *__zipHeader;
}

+ (id) archiveWithFile:(NSString *)location;
- (id) initWithFile:(NSString *)location;

- (NSString *) name;
- (NSString *) path;
- (NSUInteger) numberOfEntries;
- (NSArray *) entries;
- (NSData *) dataForEntryNamed:(NSString *)fileName;

@end
