//
//  HIErrorWindowController.h
//  Hive
//
//  Created by Jakub Suder on 30.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 Implements the error popup that shows up when an exception is caught. Exception details can be sent to the Hockeyapp
 API.
 */

@interface HIErrorWindowController : NSWindowController

@property (strong) IBOutlet NSTextField *nameField;
@property (strong) IBOutlet NSTextField *emailField;
@property (strong) IBOutlet NSTextView *comments;
@property (strong) IBOutlet NSTextView *exceptionDetails;

- (id)initWithException:(NSException *)exception;
- (IBAction)cancelReport:(id)sender;
- (IBAction)sendReport:(id)sender;

@end
