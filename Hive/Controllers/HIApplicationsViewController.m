//
//  HIApplicationsViewController.m
//  Hive
//
//  Created by Bazyli Zygan on 28.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIApplication.h"
#import "HIApplicationRuntimeViewController.h"
#import "HIApplicationsManager.h"
#import "HIApplicationsViewController.h"
#import "HIAppRuntimeBridge.h"
#import "HIContactRowView.h"
#import "HIDatabaseManager.h"
#import "HINavigationController.h"
#import "NSColor+Hive.h"
#import "NSWindow+HIShake.h"

static NSString * const AppStoreAppId = @"wei-lu.app-store";
static NSString * const AppStoreAppFilename = @"app-store";

@interface HIApplicationsViewController ()

- (IBAction)getMoreAppsClicked:(id)sender;

@end

@implementation HIApplicationsViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        self.title = NSLocalizedString(@"Apps", @"Applications view title");
        self.iconName = @"apps";
    }

    return self;
}

- (NSManagedObjectContext *)managedObjectContext {
    return DBM;
}

- (NSArray *)sortDescriptors {
    return @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
}

- (void)loadView {
    [super loadView];
    [_collectionView addObserver:self
                            forKeyPath:@"selectionIndexes"
                               options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                               context:nil];

    self.view.layer.backgroundColor = [self.collectionView.backgroundColors.firstObject hiNativeColor];
}

- (void)dealloc {
    [_collectionView removeObserver:self forKeyPath:@"selectionIndexes"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (object == self.collectionView && [keyPath isEqualTo:@"selectionIndexes"]) {
        if ([self.collectionView.selectionIndexes count] > 0) {
            NSUInteger index = self.collectionView.selectionIndexes.lastIndex;
            HIApplication *app = (HIApplication *) [_arrayController arrangedObjects][index];

            [self launchApplication:app];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView setSelectionIndexes:[NSIndexSet indexSet]];
            });
        }
    }
}

- (void)launchApplication:(HIApplication *)app {
    if ([HIAppRuntimeBridge isApiVersionInApplicationSupported:app]) {
        HIApplicationRuntimeViewController *sub = [HIApplicationRuntimeViewController new];
        sub.application = app;
        [self.navigationController pushViewController:sub animated:YES];
    } else {
        [self.view.window hiShake];
        [self showApiVersionAlert];
    }
}

- (void)showApiVersionAlert {
    NSAlert *alert = [NSAlert new];
    alert.messageText = NSLocalizedString(@"App requires a newer version of Hive.",
                                          @"Message when trying to start an app that requires a newer API level.");
    alert.informativeText = NSLocalizedString(@"To use the app, please update to the latest version of Hive.",
                                              @"Message when trying to start an app that requires a newer API level.");

    [alert beginSheetModalForWindow:self.view.window
                      modalDelegate:nil
                     didEndSelector:0
                        contextInfo:NULL];
}

- (IBAction)getMoreAppsClicked:(id)sender {
    for (HIApplication *app in self.arrayController.arrangedObjects) {
        if ([app.id isEqual:AppStoreAppId]) {
            [self launchApplication:app];
            return;
        }
    }

    NSURL *appStoreURL = [[NSBundle mainBundle] URLForResource:@"app-store" withExtension:@"hiveapp"];
    HIApplication *appStore = [[HIApplicationsManager sharedManager] installApplication:appStoreURL];
    [self launchApplication:appStore];
}

@end
