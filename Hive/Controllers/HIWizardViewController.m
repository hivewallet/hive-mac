#import "HIWizardViewController.h"

@interface HIWizardViewController ()
@end

@implementation HIWizardViewController

- (id)init {
    return [self initWithNibName:[self className] bundle:nil];
}

- (IBAction)nextButtonPressed:(id)sender {
    [self.wizardDelegate didCompleteWizardPage];
}

- (NSResponder *)initialFirstResponder {
    return nil;
}

@end
