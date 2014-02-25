//
//  HILockScreenView.h
//  Hive
//
//  Created by Jakub Suder on 24/02/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HILockScreenView : NSView

@property (nonatomic, strong) IBOutlet NSImageView *lockIcon;
@property (nonatomic, strong) IBOutlet NSTextField *passwordField;
@property (nonatomic, strong) IBOutlet NSButton *submitButton;

@end
