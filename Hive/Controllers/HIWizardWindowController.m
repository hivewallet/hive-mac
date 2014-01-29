#import "HIBreadcrumbsView.h"
#import "HIFirstRunWizardWindowController.h"
#import "HIWizardViewController.h"

@interface HIWizardWindowController()<HIWizardViewControllerDelegate>

@property (nonatomic, strong) IBOutlet NSView *wizardContentView;
@property (nonatomic, strong) IBOutlet HIBreadcrumbsView *breadcrumbView;

@property (nonatomic, strong) HIWizardViewController *currentViewController;
@property (nonatomic, assign) long index;

@end

@implementation HIWizardWindowController

- (instancetype)init {
    return [self initWithWindowNibName:[self className]];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.breadcrumbView.titles = [self.viewControllers valueForKey:@"title"];
}

- (IBAction)showWindow:(id)sender {
    [super showWindow:sender];

    self.index = -1;

    [self.window center];
    [self showNextPage];
}

- (void)showNextPage {
    [self.wizardContentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    self.index = self.index + 1;
    self.breadcrumbView.activeIndex = self.index;
    self.currentViewController = self.viewControllers[self.index];

    NSAssert([self.currentViewController isKindOfClass:[HIWizardViewController class]], nil);
    self.currentViewController.wizardDelegate = self;

    [self.currentViewController viewWillAppear];

    self.currentViewController.view.frame = self.wizardContentView.bounds;
    self.currentViewController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.wizardContentView addSubview:self.currentViewController.view];

    if (self.currentViewController.initialFirstResponder) {
        [self.window makeFirstResponder:self.currentViewController.initialFirstResponder];
    }
}

#pragma mark - HIWizardViewControllerDelegate

- (void)didCompleteWizardPage {
    if (self.hasMorePages) {
        [self showNextPage];
    } else {
        [self close];
        self.onCompletion();
    }
}

- (BOOL)hasMorePages {
    return self.index < self.viewControllers.count - 1;
}

@end
