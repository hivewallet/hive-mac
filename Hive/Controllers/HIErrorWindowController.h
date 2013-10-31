//
//  HIErrorWindowController.h
//  Hive
//
//  Created by Jakub Suder on 30.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HIErrorWindowController : NSWindowController

@property (strong) IBOutlet NSTextView *textView;

- (id)initWithException:(NSException *)exception;

@end
