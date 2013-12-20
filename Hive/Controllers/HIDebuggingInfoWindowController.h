//
//  HIDebuggingInfoWindowController.h
//  Hive
//
//  Created by Jakub Suder on 29.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 Implements the "Debugging Info" window with details about wallet contents, transactions etc.
 */

@interface HIDebuggingInfoWindowController : NSWindowController <NSWindowDelegate>

@property (strong) IBOutlet NSTextView *textView;

@end
