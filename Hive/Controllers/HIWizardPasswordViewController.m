//
//  HIWizardPasswordViewController.m
//  Hive
//
//  Created by Nikolaj Schumacher on 2014-01-19.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HIWizardPasswordViewController.h"

#import "BCClient.h"
#import "KSPasswordField.h"
#import "HIPasswordCreationInputHandler.h"

@interface HIWizardPasswordViewController ()

@property (nonatomic, strong) IBOutlet KSPasswordField *passwordField;
@property (nonatomic, strong) IBOutlet KSPasswordField *repeatedPasswordField;
@property (nonatomic, strong) IBOutlet HIPasswordCreationInputHandler *passwordCreationInputHandler;
@property (nonatomic, strong) IBOutlet NSButton *showPasswordsToggle;

@property (nonatomic, assign) BOOL submitButtonEnabled;

@end


@implementation HIWizardPasswordViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        self.title = NSLocalizedString(@"Password", @"Wizard password page title");
    }

    return self;
}

- (void)viewDidLoad {
    NSDictionary *textAttributes = @{ NSForegroundColorAttributeName: [NSColor whiteColor] };
    NSAttributedString *showPasswords = [[NSAttributedString alloc] initWithString:self.showPasswordsToggle.title
                                                                        attributes:textAttributes];
    [self.showPasswordsToggle setAttributedTitle:showPasswords];
}

- (NSResponder *)initialFirstResponder {
    return self.passwordField;
}

- (IBAction)nextButtonPressed:(id)sender {
    [self.passwordCreationInputHandler finishWithPasswordHolder:^(HIPasswordHolder *passwordHolder) {
        NSError *error = nil;
        [[BCClient sharedClient] createWalletWithPassword:passwordHolder
                                                    error:&error];
        if (error) {
            [[NSAlert alertWithError:error] runModal];
        } else {
            [self.wizardDelegate didCompleteWizardPage];
        }
    }];
}

- (IBAction)togglePasswordVisibility:(id)sender {
    [self.passwordField toggleTextShown:sender];
    [self.repeatedPasswordField toggleTextShown:sender];
}


#pragma mark - NSTextFieldDelegate

- (BOOL)control:(NSTextField *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if (commandSelector == @selector(insertNewline:)) {
        if (control.stringValue.length > 0) {
            if (control == self.passwordField) {
                [self.repeatedPasswordField becomeFirstResponder];
            } else {
                [self nextButtonPressed:control];
            }
        }
        return YES;
    } else {
        return NO;
    }
}

- (void)controlTextDidChange:(NSNotification *)notification {
    self.submitButtonEnabled = self.passwordField.stringValue.length > 0
        && self.repeatedPasswordField.stringValue.length > 0;

    [self.passwordCreationInputHandler textDidChangeInTextField:notification.object];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    [self.passwordCreationInputHandler editingDidEnd];
}

@end
