//
//  NPZip.m
//  ZipTest
//
//  Created by Bazyli Zygan on 23.11.2011.
//  Copyright (c) 2011 Hive Developers. All rights reserved.
//

#import <zlib.h>
#import "NPZip.h"

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

@interface NPZip ()

- (void) readZipHeader;
- (void) ommitHeader:(FILE *)fp;

@end

@implementation NPZip


+ (id) archiveWithFile:(NSString *)location {
	return [[NPZip alloc] initWithFile:location];
}

- (id) initWithFile:(NSString *)location {
	// check if file exists
	if (![[NSFileManager defaultManager] fileExistsAtPath:location]) {
		return nil;
	}
	
	// TODO: add test for "is readable file"
    
	self = [super init];
	
	if (self) {
		__file = location;
		__zipHeader = nil;
	}
	
	return self;
}

- (NSString *) name {
	return [__file lastPathComponent];
}

- (NSString *) path {
	return __file;
}

- (NSUInteger) numberOfEntries {
	if (__zipHeader == nil) {
		[self readZipHeader];
	}
    
	return [__zipHeader.files count];
}

- (NSArray *) entries {
	if (__zipHeader == nil) {
		[self readZipHeader];
	}
    
	return [__zipHeader.files allKeys];
}

- (void) readZipHeader {
    __zipHeader = [[NPZipHeader alloc] initWithFile:__file];
}

- (void) ommitHeader:(FILE *)fp {
/*	NPReadUInt32(fp);
	NPReadUInt16(fp);
	NPReadUInt16(fp);
    NPReadUInt16(fp);
	NPReadUInt16(fp);
	NPReadUInt16(fp);
	NPReadUInt16(fp);	
	NPReadUInt32(fp);
	NPReadUInt32(fp);
	NPReadUInt32(fp);
	uint16_t name_len = NPReadUInt16(fp);
	uint16_t extra_len = NPReadUInt16(fp);
	uint16_t comment_len = NPReadUInt16(fp);
	NPReadUInt16(fp);
	NPReadUInt16(fp);
	NPReadUInt32(fp);
    
    if (name_len > 0) {
		char *name = (char *) malloc(sizeof(char) * (name_len + 1));
		fread(name, name_len, 1, fp);
		name[name_len] = '\0';
        free(name);
	} 
	
	fseek(fp, extra_len, SEEK_CUR); // skip over extra field
	fseek(fp, comment_len, SEEK_CUR); // skip over current 
 */
	NPReadUInt32(fp);
	NPReadUInt16(fp);
	NPReadUInt16(fp);
	NPReadUInt16(fp);
	NPReadUInt16(fp);
	NPReadUInt16(fp);
	NPReadUInt32(fp);
	NPReadUInt32(fp);
	NPReadUInt32(fp);
	uint16_t name_len = NPReadUInt16(fp);
	uint16_t extra_len = NPReadUInt16(fp);
	
	
	if (name_len > 0) {
        char *name = (char *) malloc(sizeof(char) * (name_len + 1));
        fread(name, name_len, 1, fp);
        free(name);
	} 
	
	fseek(fp, extra_len, SEEK_CUR); // ignore extra field        
}

- (NSData *) dataForEntryNamed:(NSString *)fileName {
    // Some sanity checks first
    if (__zipHeader == nil)
        [self readZipHeader];
    
    NPZipFileHeader *h = [__zipHeader.files objectForKey:fileName];
    if (!h) {
        // We need to try to check if there's only one folder there
        NSString *foundRootFolder = nil;
        for (NSString *file in __zipHeader.files.allKeys) {
            if ([[file pathComponents] count] == 0)
                return nil;
            
            NSString *rootFolder = [[file pathComponents] objectAtIndex:0];
            // Ommit hidden folders
            if ([rootFolder compare:@"__MACOSX"] != NSOrderedSame &&
                ![rootFolder hasPrefix:@"."]) {
                if (!foundRootFolder || [foundRootFolder compare:rootFolder] == NSOrderedSame)
                    foundRootFolder = rootFolder;
                else
                    return nil;
            }
        }
        h = [__zipHeader.files objectForKey:[foundRootFolder stringByAppendingPathComponent:fileName]];
    }

    
    if (!h)
        return nil;
    
    NSMutableData *dat = [[NSMutableData alloc] init];
    FILE *fp = fopen([__file UTF8String], "r");

    // First seek proper place
    fseek(fp, h.local_offset, SEEK_SET);
    
    // Skip the header
    [self ommitHeader:fp];
    
    char buff[1024];
    size_t read = 0;
    size_t total_read = 0;
    size_t to_read = 0;
    // It might be, that file is uncompressed - we should simply read it to buffer
    // Then unpack it
    if (h.compressed == h.uncompressed) {
        while (total_read < h.uncompressed) {
            to_read = (h.uncompressed - total_read < 1024) ? h.uncompressed - total_read : 1024;
            read = fread(buff, 1, to_read, fp);
            total_read += read;
            [dat appendBytes:buff length:read];
        }
    } else {
        // Well.. in that particular - more probable - scenario - we have to inflate data from
        // the zip file
        z_stream stream;
        stream.zalloc = Z_NULL;
        stream.zfree = Z_NULL; // use default
        stream.opaque = 0;
        stream.next_in = Z_NULL;
        stream.avail_in = 0;

        int result = inflateInit2(&stream, -15);
        if (result != Z_OK)  {
            HILogError(@"Could not initialize zip file %@ for reading %@", __file, fileName);
            fclose(fp);
            return nil;
                
        }
        // Because we have to read it all anyway - let's read whole buffer first and then - unpack it
        NSMutableData *packed = [[NSMutableData alloc] init];
        while (total_read < h.compressed) {
            to_read = (h.compressed - total_read < 1024) ? h.compressed - total_read : 1024;
            read = fread(buff, 1, to_read, fp);
            total_read += read;
            [packed appendBytes:buff length:read];
        }
        
        // Ok, it's read. Now let's unpack
        // Set stream first
        unsigned char *unpacked_buff = (unsigned char *)malloc(h.uncompressed);

        stream.next_in = (unsigned char *)[packed bytes];
        stream.avail_in = (unsigned int)[packed length];
        stream.total_in = 0;
        stream.avail_out = h.uncompressed;
        stream.next_out = unpacked_buff;
        stream.total_out = 0;
        
        inflate(&stream, Z_SYNC_FLUSH);
        if (stream.total_out > 0) {
            [dat appendBytes:unpacked_buff length:stream.total_out];
        }
        
        free(unpacked_buff);
        inflateEnd(&stream);
        
        // Let's check if we read everything
        if ([dat length] != h.uncompressed) {
            HILogError(@"Unpack fo file %@ from %@ failed. Read %lu bytes instead of %d", fileName, __file, [dat length], h.uncompressed);
            dat = nil;
        }
        
    }
    fclose(fp);
    return dat;
}
@end
