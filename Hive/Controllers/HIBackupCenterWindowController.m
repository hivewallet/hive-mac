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
#import "HIBackupStatusCellView.h"

static const CGFloat TableRowHeight = 60.0;
static const NSTimeInterval UpdateTimerInterval = 5.0;

@interface HIBackupCenterWindowController () {
    HIBackupManager *_backupManager;
    NSTimer *_updateTimer;
    NSDateFormatter *_lastBackupDateFormatter;
}

@property (nonatomic, strong) IBOutlet NSTableView *tableView;

@end

@implementation HIBackupCenterWindowController

- (id)init {
    self = [self initWithWindowNibName:self.className];

    if (self) {
        _backupManager = [HIBackupManager sharedManager];

        _lastBackupDateFormatter = [[NSDateFormatter alloc] init];
        _lastBackupDateFormatter.dateStyle = NSDateFormatterLongStyle;
        _lastBackupDateFormatter.timeStyle = NSDateFormatterNoStyle;

        for (HIBackupAdapter *adapter in _backupManager.adapters) {
            [adapter addObserver:self forKeyPath:@"status" options:0 context:NULL];
            [adapter addObserver:self forKeyPath:@"error" options:0 context:NULL];
            [adapter addObserver:self forKeyPath:@"lastBackupDate" options:0 context:NULL];
        }

        [self startTimer];
    }

    return self;
}

- (void)dealloc {
    [self stopTimer];

    for (HIBackupAdapter *adapter in _backupManager.adapters) {
        [adapter removeObserver:self forKeyPath:@"status"];
        [adapter removeObserver:self forKeyPath:@"error"];
        [adapter removeObserver:self forKeyPath:@"lastBackupDate"];
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
    NSString *lastBackupInfo;

    if (adapter.lastBackupDate) {
        lastBackupInfo = [NSString stringWithFormat:NSLocalizedString(@"Last backup on %@",
                                                                      @"On what date was the last backup done"),
                          [_lastBackupDateFormatter stringFromDate:adapter.lastBackupDate]];
    } else {
        lastBackupInfo = NSLocalizedString(@"Backup hasn't been done yet", nil);
    }

    switch (adapter.status) {
        case HIBackupStatusDisabled:
            cell.textField.stringValue = NSLocalizedString(@"Disabled",
                                                           @"Backup status: adapter disabled");
            cell.imageView.image = [NSImage imageNamed:NSImageNameStatusNone];
            cell.statusDetailsLabel.stringValue = @"";
            break;

        case HIBackupStatusUpToDate:
            cell.textField.stringValue = NSLocalizedString(@"Up to date",
                                                           @"Backup status: backup up to date");
            cell.imageView.image = [NSImage imageNamed:NSImageNameStatusAvailable];
            cell.statusDetailsLabel.stringValue = lastBackupInfo;
            break;

        case HIBackupStatusOutdated:
            cell.textField.stringValue = NSLocalizedString(@"Backup problem",
                                                           @"Backup status: backup done but not updated recently");
            cell.imageView.image = [NSImage imageNamed:NSImageNameStatusPartiallyAvailable];
            cell.statusDetailsLabel.stringValue = [adapter.error localizedFailureReason] ?: lastBackupInfo;
            break;

        case HIBackupStatusWaiting:
            cell.textField.stringValue = NSLocalizedString(@"Waiting for backup",
                                                           @"Backup status: backup scheduled or in progress");
            cell.imageView.image = [NSImage imageNamed:NSImageNameStatusPartiallyAvailable];
            cell.statusDetailsLabel.stringValue = @"";
            break;

        case HIBackupStatusFailure:
            cell.textField.stringValue = NSLocalizedString(@"Backup error",
                                                           @"Backup status: backup can't or won't be completed");
            cell.imageView.image = [NSImage imageNamed:NSImageNameStatusUnavailable];
            cell.statusDetailsLabel.stringValue = [adapter.error localizedFailureReason] ?: lastBackupInfo;
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
    } else {
        [enableButton setTitle:NSLocalizedString(@"Enable", @"Enable backup button title")];
    }

    [enableButton setTag:row];
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
