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

static const CGFloat rowHeight = 50.0;

@interface HIBackupCenterWindowController () {
    HIBackupManager *_backupManager;
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
    }

    return self;
}

- (void)dealloc {
    for (HIBackupAdapter *adapter in _backupManager.adapters) {
        [adapter removeObserver:self forKeyPath:@"status"];
    }
}

- (void)awakeFromNib {
    self.tableView.rowHeight = rowHeight;
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

        NSRect fullRowIcon = NSMakeRect(0, 0, rowHeight, rowHeight);
        CGFloat padding = (rowHeight - adapter.iconSize) / 2.0;
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
            return NSLocalizedString(@"Disabled", @"Disabled backup adapter");
        case HIBackupStatusUpToDate:
            return NSLocalizedString(@"Up to date", @"Backup adapter up to date");
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

@end
