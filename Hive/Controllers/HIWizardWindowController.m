#import "HIWizardViewController.h"
#import "HIFirstRunWizardWindowController.h"
#import "HIBreadcrumbsView.h"

@interface HIWizardWindowController()<HIWizardViewControllerDelegate>

@property (nonatomic, strong) IBOutlet NSView *wizardContentView;
@property (nonatomic, strong) IBOutlet HIBreadcrumbsView *breadcrumbView;

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

    HIWizardViewController *controller = self.viewControllers[self.index];
    NSAssert([controller isKindOfClass:[HIWizardViewController class]], nil);
    controller.wizardDelegate = self;

    [controller viewWillAppear];

    controller.view.frame = self.wizardContentView.bounds;
    controller.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.wizardContentView addSubview:controller.view];

    if (controller.initialFirstResponder) {
        [self.window makeFirstResponder:controller.initialFirstResponder];
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
