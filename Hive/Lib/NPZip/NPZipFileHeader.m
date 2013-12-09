//
//  NPZipFileHeader.m
//  ZipTest
//
//  Created by Bazyli Zygan on 23.11.2011.
//  Copyright (c) 2011 Hive Developers. All rights reserved.
//

#import "NPZipFileHeader.h"

static uint16_t NPReadUInt16(FILE *fp) {
	uint16_t n;
	
	fread(&n, sizeof(uint16_t), 1, fp);
	
	return CFSwapInt16LittleToHost(n);
}

static uint32_t NPReadUInt32(FILE *fp) {
	uint32_t n;
	
	fread(&n, sizeof(uint32_t), 1, fp);
	
	return CFSwapInt32LittleToHost(n);
}

@implementation NPZipFileHeader

@synthesize name = __name;
@synthesize signature, made_by, min_version, flag, compression;
@synthesize last_mod_time, last_mod_date, crc, compressed, uncompressed;
@synthesize disk_start, int_attr;
@synthesize ext_attr, local_offset;

+ (id)headerFromHandler:(FILE *)fp {
    NPZipFileHeader *h = [[NPZipFileHeader alloc] init];
    
	h.signature = NPReadUInt32(fp);
	h.made_by = NPReadUInt16(fp);
	h.min_version = NPReadUInt16(fp);
	h.flag = NPReadUInt16(fp);
	h.compression = NPReadUInt16(fp);
	h.last_mod_time = NPReadUInt16(fp);
	h.last_mod_date = NPReadUInt16(fp);	
	h.crc = NPReadUInt32(fp);
	h.compressed = NPReadUInt32(fp);
	h.uncompressed = NPReadUInt32(fp);
	uint16_t name_len = NPReadUInt16(fp);
	uint16_t extra_len = NPReadUInt16(fp);
	uint16_t comment_len = NPReadUInt16(fp);
	h.disk_start = NPReadUInt16(fp);
	h.int_attr = NPReadUInt16(fp);
	h.ext_attr = NPReadUInt32(fp);
	h.local_offset = NPReadUInt32(fp);    

    if (name_len > 0) {
		char *name = (char *) malloc(sizeof(char) * (name_len + 1));
		fread(name, name_len, 1, fp);
		name[name_len] = '\0';
        h.name = [NSString stringWithUTF8String:name];
        free(name);
	} 
	
	fseek(fp, extra_len, SEEK_CUR); // skip over extra field
	fseek(fp, comment_len, SEEK_CUR); // skip over current
    return h;
}

@end
