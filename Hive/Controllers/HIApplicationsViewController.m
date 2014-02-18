//
//  HIApplicationsViewController.m
//  Hive
//
//  Created by Bazyli Zygan on 28.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIApplication.h"
#import "HIApplicationRuntimeViewController.h"
#import "HIApplicationsViewController.h"
#import "HIAppRuntimeBridge.h"
#import "HIContactRowView.h"
#import "HIDatabaseManager.h"
#import "HINavigationController.h"
#import "NSColor+Hive.h"
#import "NSWindow+HIShake.h"

@interface HIApplicationsViewController ()

- (IBAction)getMoreAppsClicked:(id)sender;

@end

@implementation HIApplicationsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
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

            if ([HIAppRuntimeBridge isApiVersionInApplicationSupported:app]) {
                HIApplicationRuntimeViewController *sub = [HIApplicationRuntimeViewController new];
                sub.application = app;
                [self.navigationController pushViewController:sub animated:YES];
            } else {
                [self.view.window hiShake];
                [self showApiVersionAlert];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView setSelectionIndexes:[NSIndexSet indexSet]];
            });

        }
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
    [[NSWorkspace sharedWorkspace] openURL:
     [NSURL URLWithString:@"https://github.com/hivewallet/hive-osx/wiki/App-Registry"]];
}

@end
