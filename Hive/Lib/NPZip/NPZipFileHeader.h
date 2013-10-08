//
//  NPZipFileHeader.h
//  ZipTest
//
//  Created by Bazyli Zygan on 23.11.2011.
//  Copyright (c) 2011 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NPZipFileHeader : NSObject
{
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, assign) uint32_t signature; /* 0x02014b50 */
@property (nonatomic, assign) uint16_t made_by;
@property (nonatomic, assign) uint16_t min_version;
@property (nonatomic, assign) uint16_t flag;
@property (nonatomic, assign) uint16_t compression;
@property (nonatomic, assign) uint16_t last_mod_time;
@property (nonatomic, assign) uint16_t last_mod_date;
@property (nonatomic, assign) uint32_t crc;
@property (nonatomic, assign) uint32_t compressed; // compressed size
@property (nonatomic, assign) uint32_t uncompressed; // uncrompressed size
@property (nonatomic, assign) uint16_t disk_start;
@property (nonatomic, assign) uint16_t int_attr;
@property (nonatomic, assign) uint32_t ext_attr;
@property (nonatomic, assign) uint32_t local_offset;	

+ (id)headerFromHandler:(FILE *)fp;

@end
