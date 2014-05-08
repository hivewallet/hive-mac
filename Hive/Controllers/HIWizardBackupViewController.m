//
//  HIWizardBackupViewController.m
//  Hive
//
//  Created by Nikolaj Schumacher on 2014-01-19.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import "HIBackupAdapter.h"
#import "HIBackupManager.h"
#import "HIWizardBackupViewController.h"

@interface HIWizardBackupViewController ()

@property (nonatomic, copy) NSImage *icon1;
@property (nonatomic, copy) NSString *name1;
@property (nonatomic, copy) NSImage *icon2;
@property (nonatomic, copy) NSString *name2;
@property (nonatomic, assign) BOOL enabled1;
@property (nonatomic, assign) BOOL enabled2;

@end

@implementation HIWizardBackupViewController {
    BOOL enableConfiguration;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        self.title = NSLocalizedString(@"Backup", @"Wizard backup page title");

        for (HIBackupAdapter *adapter in [[HIBackupManager sharedManager] visibleAdapters]) {
            [adapter addObserver:self forKeyPath:@"enabled" options:0 context:NULL];
        }
    }

    return self;
}

- (void)dealloc {
    for (HIBackupAdapter *adapter in [[HIBackupManager sharedManager] visibleAdapters]) {
        [adapter removeObserver:self forKeyPath:@"enabled"];
    }
}

- (void)viewWillAppear {
    [[HIBackupManager sharedManager] resetSettings];
    [[HIBackupManager sharedManager] initializeAdapters];

    dispatch_async(dispatch_get_main_queue(), ^{
        [[HIBackupManager sharedManager] performBackups];
    });
}

- (HIBackupAdapter *)backupAdapterAtIndex:(int)index {
    return [[HIBackupManager sharedManager] visibleAdapters][index];
}

// TODO make this more DRY

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

- (NSString *)title1 {
    return [self titleForAdapter:[self backupAdapterAtIndex:0]];
}

- (NSString *)title2 {
    return [self titleForAdapter:[self backupAdapterAtIndex:1]];
}

- (NSString *)titleForAdapter:(HIBackupAdapter *)adapter {
    if (adapter.enabled) {
        return NSLocalizedString(@"Disable", @"Disable backup button title");
    } else if ([self adapterShouldBeConfigured:adapter]) {
        return NSLocalizedString(@"Enable...", @"Enable backup button title (requires configuration)");
    } else {
        return NSLocalizedString(@"Enable", @"Enable backup button title (no configuration required)");
    }
}

- (BOOL)adapterShouldBeConfigured:(HIBackupAdapter *)adapter {
    return adapter.needsToBeConfigured || (adapter.canBeConfigured && enableConfiguration);
}

- (IBAction)enable1:(id)sender {
    [self enableAdapter:[self backupAdapterAtIndex:0]];
}

- (IBAction)enable2:(id)sender {
    [self enableAdapter:[self backupAdapterAtIndex:1]];
}

- (void)enableAdapter:(HIBackupAdapter *)adapter {
    if (!adapter.enabled && [self adapterShouldBeConfigured:adapter]) {
        [adapter configureInWindow:self.view.window];
    } else {
        adapter.enabled = !adapter.enabled;
    }

    [adapter performBackupIfEnabled];
}

- (void)keyFlagsChanged:(NSUInteger)flags inWindow:(NSWindow *)window {
    BOOL wasEnabled = enableConfiguration;
    enableConfiguration = (flags & NSAlternateKeyMask) > 0;

    if (enableConfiguration != wasEnabled) {
        [self updateButtonTitles];
    }
}

- (void)updateButtonTitles {
    [self willChangeValueForKey:@"title1"];
    [self didChangeValueForKey:@"title1"];
    [self willChangeValueForKey:@"title2"];
    [self didChangeValueForKey:@"title2"];
}

- (void)observeValueForKeyPath:(NSString *)path ofObject:(id)object change:(NSDictionary *)change context:(void *)ctx {
    if ([object isKindOfClass:HIBackupAdapter.class]) {
        [self updateButtonTitles];

        [self willChangeValueForKey:@"enabled1"];
        [self didChangeValueForKey:@"enabled1"];
        [self willChangeValueForKey:@"enabled2"];
        [self didChangeValueForKey:@"enabled2"];
    }
}

@end
