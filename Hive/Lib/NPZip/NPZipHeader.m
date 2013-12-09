//
//  NPZipHeader.m
//  ZipTest
//
//  Created by Bazyli Zygan on 23.11.2011.
//  Copyright (c) 2011 Hive Developers. All rights reserved.
//

#import "NPZipHeader.h"

#define ZIP_DISK_TRAILER	(0x06054b50)
#define ZIP_BUFF_SIZE	512

typedef struct {
	uint32_t signature;
	uint16_t curr_disk;
	uint16_t cd_disk;
	uint16_t nr_files_disk;
	uint16_t nr_files;
	uint32_t cd_len;
	uint32_t cd_offset;
	uint16_t comment_len;
} CDERecord;

static BOOL isDiskTrailer(char *start) {
	return (*(start+1) == 0x4b) && (*(start+2) == 0x05) && (*(start+3) == 0x06);
}

@interface NPZipHeader ()

- (void)readHeaderFromFile:(NSString *)file;
- (long)trailerPositionInFile:(FILE *)file size:(long)size;

@end

@implementation NPZipHeader

@synthesize files = __files;

- (id)initWithFile:(NSString *)filePath {
    self = [self init];
    if (self) {
        [self readHeaderFromFile:filePath];
    }
    
    return self;
}

- (long)trailerPositionInFile:(FILE *)file size:(long)size {
	char *buffer = (char *) calloc(ZIP_BUFF_SIZE, sizeof(char));
	long offset, buflen, trailerPosition;
	
	// Loop thru the zip file from the end backwards, ZIP_BUFF_SIZE bytes a time to find
	// the ZIP_DISK_TRAILER
	offset = size;
	buflen = 0;
	trailerPosition = -1;
	
	while (offset > 0) {
		offset -= ZIP_BUFF_SIZE;
		offset += 20; // keep some overlap
		buflen = ZIP_BUFF_SIZE;
        
		if (offset < 0) {
			offset = 0;
		}
		
		if (offset + buflen > size) {
			buflen = size - offset;
		}
		
		fseek(file, offset, SEEK_SET);
		fread(buffer, sizeof(char), buflen, file);
		
		// loop thru buf to find byte marker
		char *pos;
		for (pos = buffer + buflen; pos >= buffer; pos--) {
			if (*pos == 0x50 && isDiskTrailer(pos)) {
				trailerPosition = offset + (pos - buffer);
				goto positionBreak;
			}
		} 
	}
	
positionBreak:
	
	free(buffer);
	return trailerPosition;    
}

- (void)readHeaderFromFile:(NSString *)file {
	CDERecord trailer;
	long filesize, trailerPosition, file_count;
	FILE *fp = fopen([file UTF8String], "r");
	
	fseek(fp, 0, SEEK_END);
	filesize = (int) ftell(fp);
	
	trailerPosition = [self trailerPositionInFile:fp size:filesize];
	if (trailerPosition < 0)  {
		return;
	}
	
	__files = [[NSMutableDictionary alloc] init];
	
	
	fseek(fp, trailerPosition, SEEK_SET);
	fread(&trailer, sizeof(CDERecord), 1, fp);
	
	file_count = CFSwapInt16LittleToHost(trailer.nr_files);
	unsigned int cd_pos = CFSwapInt32LittleToHost(trailer.cd_offset);
	
	
	unsigned int i;
	fseek(fp, cd_pos, SEEK_SET);
	for (i=0; i<file_count; i++) {
        NPZipFileHeader *header = [NPZipFileHeader headerFromHandler:(FILE *)fp];
        if (header && [header.name length] > 0)
            [__files setObject:header forKey:header.name];
	}
	
	fclose(fp);
    
    // Now - it might happen that all files are put in single dictionary.
    // In that scenario we should truncate that folder name
    @autoreleasepool {
        if ([[__files allValues] count] > 0) {
            NSString *firstPathCmp = [[[[__files allKeys] objectAtIndex:0] componentsSeparatedByString:@"/"] objectAtIndex:0];
            int l = (int)[firstPathCmp length] + 1;
            BOOL common = YES;
            NSRange r;
            for (NSString *k in [__files allKeys]) {
                r = [k rangeOfString:firstPathCmp];
                if (r.location == NSNotFound) {
                    common = NO;
                    break;
                }
            }            
            
            if (common) {
                NPZipFileHeader *h = nil;
                NSArray *keys = [[__files allKeys] copy];
                for (NSString *k in keys) {
                    h = [__files objectForKey:k];
                    [__files setObject:h forKey:[k substringFromIndex:l]];
                    [__files removeObjectForKey:k];
                }
            }
        }
    }
    
}

@end
