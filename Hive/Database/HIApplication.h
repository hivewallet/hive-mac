//
//  HIApplication.h
//  Hive
//
//  Created by Bazyli Zygan on 27.06.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

extern NSString * const HIApplicationEntity;


/*
 A single application, displayed in the Applications tab. An application has an HIApplication record in the database,
 and also a bundle file in ~/Library/Application Support/Hive/Applications.
 */

@interface HIApplication : NSManagedObject

@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSURL * path;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, readonly) NSImage *icon;
@property (nonatomic, readonly) NSDictionary *manifest;

- (void)refreshIcon;

@end
