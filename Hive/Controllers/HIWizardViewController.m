#import "HIWizardViewController.h"

@interface HIWizardViewController ()
@end

@implementation HIWizardViewController

- (instancetype)init {
    return [self initWithNibName:[self className] bundle:nil];
}

- (IBAction)nextButtonPressed:(id)sender {
    [self.wizardDelegate didCompleteWizardPage];
}

- (NSResponder *)initialFirstResponder {
    return nil;
}

- (void)viewWillAppear {
}

@end
