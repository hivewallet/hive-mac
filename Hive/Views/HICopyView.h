//
//  HICopyView.h
//  Hive
//
//  Created by Bazyli Zygan on 23.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 A transparent overlay view, intended to be added on top of other views, which copies the value from contentToCopy
 property to the clipboard when it's clicked. Used for copying user's and contacts' bitcoin addresses.
 */

@interface HICopyView : NSView

@property (nonatomic, copy) NSString *contentToCopy;

@end
