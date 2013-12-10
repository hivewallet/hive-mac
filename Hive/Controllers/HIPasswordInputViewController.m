//
//  HIPasswordInputViewController.m
//  Hive
//
//  Created by Nikolaj Schumacher on 2013-12-09.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIPasswordInputViewController.h"

#import "HIPasswordHolder.h"

@interface HIPasswordInputViewController ()<NSTextFieldDelegate>

@property (nonatomic, strong) IBOutlet NSSecureTextField *passwordField;

@property (nonatomic, assign) BOOL submitButtonEnabled;

@end

@implementation HIPasswordInputViewController

- (id)init {
    return [self initWithNibName:[self className] bundle:nil];
}

- (IBAction)submit:(id)sender {
    HIPasswordHolder *passwordHolder = [[HIPasswordHolder alloc] initWithString:self.passwordField.stringValue];
    @try {
        self.passwordField.stringValue = @"";
        if (self.onSubmit) {
            self.onSubmit(passwordHolder);
        }
    } @finally {
        [passwordHolder clear];
    }
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)notification {
    self.submitButtonEnabled = self.passwordField.stringValue.length > 0;
}

@end
