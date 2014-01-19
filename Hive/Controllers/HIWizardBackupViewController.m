//
//  HIWizardBackupViewController.m
//  Hive
//
//  Created by Nikolaj Schumacher on 2014-01-19.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HIWizardBackupViewController.h"
#import "HIBackupManager.h"
#import "HIBackupAdapter.h"

@interface HIWizardBackupViewController ()

@property (nonatomic, copy) NSImage *icon1;
@property (nonatomic, copy) NSString *name1;
@property (nonatomic, copy) NSImage *icon2;
@property (nonatomic, copy) NSString *name2;
@property (nonatomic, assign) BOOL enabled1;
@property (nonatomic, assign) BOOL enabled2;

@end

@implementation HIWizardBackupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Backup", @"Wizard backup page title");
    }
    return self;
}

- (HIBackupAdapter *)backupAdapterAtIndex:(int)index {
    return [HIBackupManager sharedManager].adapters[index];
}

- (NSImage *)icon1 {
    return [self backupAdapterAtIndex:0].icon;
}

- (NSString *)name1 {
    return [self backupAdapterAtIndex:0].displayedName;
}

- (NSImage *)icon2 {
    return [self backupAdapterAtIndex:1].icon;
}

- (NSString *)name2 {
    return [self backupAdapterAtIndex:1].displayedName;
}

- (BOOL)enabled1 {
    return [self backupAdapterAtIndex:0].enabled;
}

- (BOOL)enabled2 {
    return [self backupAdapterAtIndex:1].enabled;
}

- (IBAction)enable1:(id)sender {
    HIBackupAdapter *adapter = [self backupAdapterAtIndex:0];
    if (!adapter.enabled && adapter.needsToBeConfigured) {
        [adapter configureInWindow:self.view.window];
    }
}

- (IBAction)enable2:(id)sender {
    HIBackupAdapter *adapter = [self backupAdapterAtIndex:1];
    if (!adapter.enabled && adapter.needsToBeConfigured) {
        [adapter configureInWindow:self.view.window];
    }
}

@end
