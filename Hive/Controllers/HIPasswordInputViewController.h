//
//  HIPasswordInputViewController.h
//  Hive
//
//  Created by Nikolaj Schumacher on 2013-12-09.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

@class HIPasswordHolder;

/*
 Requests an input from the user.
 */
@interface HIPasswordInputViewController : NSViewController

@property (nonatomic, copy) NSString *prompt;
@property (nonatomic, copy) NSString *submitLabel;

@property (nonatomic, copy) void (^onSubmit)(HIPasswordHolder *passwordHolder);

@property (nonatomic, strong, readonly) NSString *password;

@end
