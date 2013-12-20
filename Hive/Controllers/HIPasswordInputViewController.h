//
//  HIPasswordInputViewController.h
//  Hive
//
//  Created by Nikolaj Schumacher on 2013-12-09.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

@class HIPasswordHolder;

/*
 A popup which requests a password from the user and keeps it in a secure storage.
 */

@interface HIPasswordInputViewController : NSViewController

@property (nonatomic, copy) NSString *prompt;
@property (nonatomic, copy) NSString *submitLabel;

@property (nonatomic, copy) void (^onSubmit)(HIPasswordHolder *passwordHolder);

- (void)resetInput;

@end
