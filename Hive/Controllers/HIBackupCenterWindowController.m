//
//  HIBackupCenterWindowController.m
//  Hive
//
//  Created by Jakub Suder on 23.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIBackupCenterWindowController.h"
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
    }

    return self;
}

- (void)awakeFromNib {
    self.tableView.rowHeight = rowHeight;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _backupManager.adapters.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    HIBackupAdapter *adapter = _backupManager.adapters[row];
    NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];

    cell.textField.stringValue = adapter.name;
    cell.imageView.image = adapter.icon;

    NSRect fullRowIcon = NSMakeRect(0, 0, rowHeight, rowHeight);
    CGFloat padding = (rowHeight - adapter.iconSize) / 2.0;
    cell.imageView.frame = NSInsetRect(fullRowIcon, padding, padding);

    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    [self.tableView deselectAll:self];
}

@end
