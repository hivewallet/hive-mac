//
//  HIBackupCenterWindowController.m
//  Hive
//
//  Created by Jakub Suder on 23.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIBackupCenterWindowController.h"
#import "HIBackupActionsCellView.h"
#import "HIBackupAdapter.h"
#import "HIBackupManager.h"

static const CGFloat TableRowHeight = 50.0;
static const NSTimeInterval UpdateTimerInterval = 5.0;

@interface HIBackupCenterWindowController () {
    HIBackupManager *_backupManager;
    NSTimer *_updateTimer;
}

@property (nonatomic, strong) IBOutlet NSTableView *tableView;

@end

@implementation HIBackupCenterWindowController

- (id)init {
    self = [self initWithWindowNibName:self.className];

    if (self) {
        _backupManager = [HIBackupManager sharedManager];

        for (HIBackupAdapter *adapter in _backupManager.adapters) {
            [adapter addObserver:self forKeyPath:@"status" options:0 context:NULL];
        }

        [self startTimer];
    }

    return self;
}

- (void)dealloc {
    [self stopTimer];

    for (HIBackupAdapter *adapter in _backupManager.adapters) {
        [adapter removeObserver:self forKeyPath:@"status"];
    }
}

- (void)awakeFromNib {
    self.tableView.rowHeight = TableRowHeight;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _backupManager.adapters.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    HIBackupAdapter *adapter = _backupManager.adapters[row];
    HIBackupAdapterStatus status = adapter.status;

    NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];

    if ([tableColumn.identifier isEqual:@"Name"]) {
        cell.textField.stringValue = adapter.displayedName;
        cell.imageView.image = adapter.icon;

        NSRect fullRowIcon = NSMakeRect(0, 0, TableRowHeight, TableRowHeight);
        CGFloat padding = (TableRowHeight - adapter.iconSize) / 2.0;
        cell.imageView.frame = NSInsetRect(fullRowIcon, padding, padding);
    } else if ([tableColumn.identifier isEqual:@"Status"]) {
        cell.textField.stringValue = [self statusNameForStatus:status];
        cell.imageView.image = [self statusImageForStatus:status];
    } else {
        NSButton *enableButton = [(HIBackupActionsCellView *)cell enableButton];

        if (adapter.enabled) {
            [enableButton setTitle:NSLocalizedString(@"Disable", @"Disable backup button title")];
        } else {
            [enableButton setTitle:NSLocalizedString(@"Enable", @"Enable backup button title")];
        }

        [enableButton setTag:row];
    }

    return cell;
}

- (NSString *)statusNameForStatus:(HIBackupAdapterStatus)status {
    switch (status) {
        case HIBackupStatusDisabled:
            return NSLocalizedString(@"Disabled", @"Backup adapter status: adapter disabled");
        case HIBackupStatusUpToDate:
            return NSLocalizedString(@"Up to date", @"Backup adapter status: backup up to date");
        case HIBackupStatusOutdated:
            return NSLocalizedString(@"Backup problem", @"Backup adapter status: backup done but not updated recently");
        case HIBackupStatusWaiting:
            return NSLocalizedString(@"Waiting for backup", @"Backup adapter status: backup scheduled or in progress");
        case HIBackupStatusFailure:
            return NSLocalizedString(@"Backup error", @"Backup adapter status: backup can't or won't be completed");
        default:
            return @"Unknown status";
    }
}

- (NSImage *)statusImageForStatus:(HIBackupAdapterStatus)status {
    switch (status) {
        case HIBackupStatusDisabled:
            return [NSImage imageNamed:NSImageNameStatusNone];
        case HIBackupStatusUpToDate:
            return [NSImage imageNamed:NSImageNameStatusAvailable];
        case HIBackupStatusOutdated:
        case HIBackupStatusWaiting:
            return [NSImage imageNamed:NSImageNameStatusPartiallyAvailable];
        default:
            return [NSImage imageNamed:NSImageNameStatusUnavailable];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    [self.tableView deselectAll:self];
}

- (IBAction)enableButtonClicked:(id)sender {
    NSInteger row = [sender tag];
    HIBackupAdapter *adapter = _backupManager.adapters[row];

    if (adapter) {
        adapter.enabled = !adapter.enabled;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    HIBackupAdapter *adapter = object;
    NSUInteger row = [_backupManager.adapters indexOfObject:adapter];

    if (row != NSNotFound) {
        [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
                                  columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)]];
    }
}

- (void)updateStatus {
    [_backupManager.adapters makeObjectsPerformSelector:@selector(updateStatus)];
}

- (void)startTimer {
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval:UpdateTimerInterval
                                                    target:self
                                                  selector:@selector(updateStatus)
                                                  userInfo:nil
                                                   repeats:YES];

    if ([_updateTimer respondsToSelector:@selector(setTolerance:)]) {
        _updateTimer.tolerance = 1.0;
    }

    [self updateStatus];
}

- (void)stopTimer {
    [_updateTimer invalidate];
    _updateTimer = nil;
}

// mavericks fuck yeah
- (void)windowDidChangeOcclusionState:(NSNotification *)notification {
    BOOL visible = (self.window.occlusionState & NSWindowOcclusionStateVisible);

    if (visible && !_updateTimer) {
        [self startTimer];
    } else if (!visible && _updateTimer) {
        [self stopTimer];
    }
}

@end
