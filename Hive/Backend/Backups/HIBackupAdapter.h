//
//  HIBackupAdapter.h
//  Hive
//
//  Created by Jakub Suder on 23.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, HIBackupAdapterStatus) {
    HIBackupStatusDisabled,
    HIBackupStatusUpToDate,
};

@interface HIBackupAdapter : NSObject

@property (readonly) NSString *name;
@property (readonly) NSString *displayedName;
@property (readonly) NSImage *icon;
@property (readonly) CGFloat iconSize;
@property (nonatomic, readonly) HIBackupAdapterStatus status;
@property (nonatomic, getter = isEnabled) BOOL enabled;

+ (NSDictionary *)backupSettings;
- (BOOL)isEnabledByDefault;

@end
