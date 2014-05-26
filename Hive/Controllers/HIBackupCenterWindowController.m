//
//  HIBackupCenterWindowController.m
//  Hive
//
//  Created by Jakub Suder on 23.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HIBackupActionsCellView.h"
#import "HIBackupAdapter.h"
#import "HIBackupCenterWindowController.h"
#import "HIBackupManager.h"
#import "HIBackupStatusCellView.h"
#import "NSAlert+Hive.h"

static const CGFloat TableRowHeight = 60.0;
static const NSTimeInterval UpdateTimerInterval = 5.0;

@interface HIBackupCenterWindowController () {
    NSArray *_adapters;
    NSTimer *_updateTimer;
    BOOL enableConfiguration;
}

@property (nonatomic, strong) IBOutlet NSTableView *tableView;

@end

@implementation HIBackupCenterWindowController

- (instancetype)init {
    self = [self initWithWindowNibName:self.className];

    if (self) {
        _adapters = [[HIBackupManager sharedManager] visibleAdapters];

        for (HIBackupAdapter *adapter in _adapters) {
            [adapter addObserver:self forKeyPath:@"status" options:0 context:NULL];
            [adapter addObserver:self forKeyPath:@"error" options:0 context:NULL];
            [adapter addObserver:self forKeyPath:@"lastBackupDate" options:0 context:NULL];
        }

        [self startTimer];
    }

    return self;
}

- (void)dealloc {
    NSAssert(![_updateTimer isValid], @"Retain cycle not broken");

    for (HIBackupAdapter *adapter in _adapters) {
        [adapter removeObserver:self forKeyPath:@"status"];
        [adapter removeObserver:self forKeyPath:@"error"];
        [adapter removeObserver:self forKeyPath:@"lastBackupDate"];
    }

    _tableView.delegate = nil;
    _tableView.dataSource = nil;
}

- (void)awakeFromNib {
    self.tableView.rowHeight = TableRowHeight;
}

- (void)windowWillClose:(NSNotification *)notification {
    [self stopTimer];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _adapters.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    HIBackupAdapter *adapter = _adapters[row];
    NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];

    if ([tableColumn.identifier isEqual:@"Name"]) {
        [self updateNameCell:cell forAdapter:adapter inRow:row];
    } else if ([tableColumn.identifier isEqual:@"Status"]) {
        [self updateStatusCell:(HIBackupStatusCellView *)cell forAdapter:adapter inRow:row];
    } else {
        [self updateActionsCell:(HIBackupActionsCellView *)cell forAdapter:adapter inRow:row];
    }

    return cell;
}

- (void)updateNameCell:(NSTableCellView *)cell forAdapter:(HIBackupAdapter *)adapter inRow:(NSInteger)row {
    cell.textField.stringValue = adapter.displayedName;
    cell.imageView.image = adapter.icon;

    NSRect fullRowIcon = NSMakeRect(0, 0, TableRowHeight, TableRowHeight);
    CGFloat padding = (TableRowHeight - adapter.iconSize) / 2.0;
    cell.imageView.frame = NSInsetRect(fullRowIcon, padding, padding);
}

- (void)updateStatusCell:(HIBackupStatusCellView *)cell forAdapter:(HIBackupAdapter *)adapter inRow:(NSInteger)row {
    switch (adapter.status) {
        case HIBackupStatusDisabled:
            cell.textField.stringValue = HIBackupStatusTextDisabled;
            cell.imageView.image = [NSImage imageNamed:NSImageNameStatusNone];
            cell.statusDetailsLabel.stringValue = @"";
            break;

        case HIBackupStatusUpToDate:
            cell.textField.stringValue = HIBackupStatusTextUpToDate;
            cell.imageView.image = [NSImage imageNamed:NSImageNameStatusAvailable];
            cell.statusDetailsLabel.stringValue = adapter.lastBackupInfo;
            break;

        case HIBackupStatusOutdated:
            cell.textField.stringValue = HIBackupStatusTextOutdated;
            cell.imageView.image = [NSImage imageNamed:NSImageNameStatusPartiallyAvailable];
            cell.statusDetailsLabel.stringValue = adapter.errorMessage ?: adapter.lastBackupInfo;
            break;

        case HIBackupStatusWaiting:
            cell.textField.stringValue = HIBackupStatusTextWaiting;
            cell.imageView.image = [NSImage imageNamed:NSImageNameStatusPartiallyAvailable];
            cell.statusDetailsLabel.stringValue = @"";
            break;

        case HIBackupStatusFailure:
            cell.textField.stringValue = HIBackupStatusTextFailure;
            cell.imageView.image = [NSImage imageNamed:NSImageNameStatusUnavailable];
            cell.statusDetailsLabel.stringValue = adapter.errorMessage ?: adapter.lastBackupInfo;
            break;

        default:
            cell.textField.stringValue = @"Unknown status";
            cell.imageView.image = [NSImage imageNamed:NSImageNameStatusUnavailable];
            cell.statusDetailsLabel.stringValue = @"";
    }
}

- (void)updateActionsCell:(HIBackupActionsCellView *)cell forAdapter:(HIBackupAdapter *)adapter inRow:(NSInteger)row {
    NSButton *enableButton = [cell enableButton];

    if (adapter.enabled) {
        [enableButton setTitle:NSLocalizedString(@"Disable", @"Disable backup button title")];
    } else if ([self adapterShouldBeConfigured:adapter]) {
        [enableButton setTitle:NSLocalizedString(@"Enable...", @"Enable backup button title (requires configuration)")];
    } else {
        [enableButton setTitle:NSLocalizedString(@"Enable", @"Enable backup button title (no configuration required)")];
    }

    [enableButton setTag:row];

    NSRect frame = enableButton.frame;
    frame.size.width = enableButton.intrinsicContentSize.width;
    enableButton.frame = frame;
}

- (BOOL)adapterShouldBeConfigured:(HIBackupAdapter *)adapter {
    return adapter.needsToBeConfigured || (adapter.canBeConfigured && enableConfiguration);
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    [self.tableView deselectAll:self];
}

- (IBAction)enableButtonClicked:(id)sender {
    NSInteger row = [sender tag];
    HIBackupAdapter *adapter = _adapters[row];

    if (!adapter) {
        return;
    }

    BOOL isEncrypted = [[BCClient sharedClient] isWalletPasswordProtected];

    if (!adapter.enabled && adapter.requiresEncryption && !isEncrypted) {
        NSAlert *alert = [NSAlert hiOKAlertWithTitle:NSLocalizedString(@"You need to set a wallet password first "
                                                                       @"(see Wallet menu).",
                                                                       @"Backup requires password alert title")
                                             message:NSLocalizedString(@"It's dangerous to upload unencrypted wallets.",
                                                                       @"Backup requires password alert details")];

        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
        return;
    }

    if (!adapter.enabled && [self adapterShouldBeConfigured:adapter]) {
        [adapter configureInWindow:self.window];
    } else {
        adapter.enabled = !adapter.enabled;
    }
}

- (void)keyFlagsChanged:(NSUInteger)flags inWindow:(NSWindow *)window {
    enableConfiguration = (flags & NSAlternateKeyMask) > 0;

    for (NSInteger i = 0; i < _adapters.count; i++) {
        HIBackupActionsCellView *cell = [self.tableView viewAtColumn:2 row:i makeIfNecessary:YES];
        HIBackupAdapter *adapter = _adapters[i];

        [self updateActionsCell:cell forAdapter:adapter inRow:i];
    }
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    [self keyFlagsChanged:[NSEvent modifierFlags] inWindow:self.window];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    HIBackupAdapter *adapter = object;
    NSUInteger row = [_adapters indexOfObject:adapter];

    if (row != NSNotFound) {
        [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
                                  columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)]];
    }
}

- (void)updateStatus {
    [_adapters makeObjectsPerformSelector:@selector(updateStatusIfEnabled)];
}

- (void)startTimer {
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval:UpdateTimerInterval
                                                    target:self
                                                  selector:@selector(updateStatus)
                                                  userInfo:nil
                                                   repeats:YES];

    #pragma deploymate push "ignored-api-availability"
    if ([_updateTimer respondsToSelector:@selector(setTolerance:)]) {
        _updateTimer.tolerance = 1.0;
    }
    #pragma deploymate pop

    [self updateStatus];
}

- (void)stopTimer {
    [_updateTimer invalidate];
    _updateTimer = nil;
}

// mavericks fuck yeah
- (void)windowDidChangeOcclusionState:(NSNotification *)notification {
    #pragma deploymate push "ignored-api-availability"
    BOOL visible = (self.window.occlusionState & NSWindowOcclusionStateVisible);
    #pragma deploymate pop

    if (visible && !_updateTimer) {
        [self startTimer];
    } else if (!visible && _updateTimer) {
        [self stopTimer];
    }
}

@end
