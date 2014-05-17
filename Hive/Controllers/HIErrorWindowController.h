//
//  HIErrorWindowController.h
//  Hive
//
//  Created by Jakub Suder on 30.10.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

/*
 Implements the error popup that shows up when an exception is caught. Exception details can be sent to the Hockeyapp
 API.
 */

@interface HIErrorWindowController : NSWindowController

- (instancetype)initWithException:(NSException *)exception;
- (IBAction)cancelReport:(id)sender;
- (IBAction)sendReport:(id)sender;

@end
