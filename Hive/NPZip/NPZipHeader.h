//
//  NPZipHeader.h
//  ZipTest
//
//  Created by Bazyli Zygan on 23.11.2011.
//  Copyright (c) 2011 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPZipFileHeader.h"

@interface NPZipHeader : NSObject
{
@private    
	uint32_t signature; /* 0x04034b50 */
	uint16_t min_version;
	uint16_t flag;
	uint16_t compression;
	uint16_t last_mod_time;
	uint16_t last_mod_date;
	uint32_t crc32;
	uint32_t compressed;
	uint32_t uncompressed;
	uint16_t name_len;
	uint16_t extra_len;    
}

@property (nonatomic, retain) NSMutableDictionary *files;

- (id)initWithFile:(NSString *)filePath;

@end
