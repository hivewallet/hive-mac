//
//  HIContactsViewController.m
//  Hive
//
//  Created by Bazyli Zygan on 28.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIContact.h"
#import "HIContactRowView.h"
#import "HIContactsViewController.h"
#import "HIContactViewController.h"
#import "HINavigationController.h"
#import "HINewContactViewController.h"
#import "NSColor+Hive.h"


@implementation HIContactsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        self.title = NSLocalizedString(@"Contacts", @"Contacts view title");
        self.iconName = @"group";
    }
    
    return self;
}

- (void)awakeFromNib {
    [self.foreverAloneScreen setFrame:self.view.bounds];
    [self.foreverAloneScreen setHidden:YES];
    [self.foreverAloneScreen.layer setBackgroundColor:[[NSColor hiWindowBackgroundColor] hiNativeColor]];
    [self.view addSubview:self.foreverAloneScreen];

    [self.arrayController addObserver:self
                           forKeyPath:@"arrangedObjects.@count"
                              options:NSKeyValueObservingOptionInitial
                              context:NULL];
}

- (void)viewWillAppear {
    [self.arrayController rearrangeObjects];
}

- (void)dealloc {
    [self.arrayController removeObserver:self forKeyPath:@"arrangedObjects.@count"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (object == self.arrayController) {
        [self updateForeverAloneScreen];
    }
}

- (void)updateForeverAloneScreen {
    // don't take count from arrangedObjects because array controller might not have fetched data yet
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HIContactEntity];
    NSUInteger count = [DBM countForFetchRequest:request error:NULL];

    BOOL hasFriends = count > 0;
    [self.foreverAloneScreen setHidden:hasFriends];
    [self.scrollView setHidden:!hasFriends];
}

- (NSView *)rightNavigationView {
    return _navigationView;
}

- (IBAction)newContactClicked:(NSButton *)sender {
    [self.navigationController pushViewController:[HINewContactViewController new] animated:YES];
}

- (NSManagedObjectContext *)managedObjectContext {
    return DBM;
}

- (NSArray *)sortDescriptors {
    return @[[NSSortDescriptor sortDescriptorWithKey:@"lastname" ascending:YES],
             [NSSortDescriptor sortDescriptorWithKey:@"firstname" ascending:YES]];
}

#pragma mark - NSTableViewDataSource




#pragma mark - NSTableViewDelegate

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    return [HIContactRowView new];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) {
        return;
    }

    NSTableCellView *cell = [self.tableView viewAtColumn:0 row:row makeIfNecessary:NO];
    [cell setNeedsDisplay:YES];

    dispatch_async(dispatch_get_main_queue(), ^{
        HIViewController *sub = [[HIContactViewController alloc] initWithContact:_arrayController.arrangedObjects[row]];
        
        [self.navigationController pushViewController:sub animated:YES];

        [self.tableView deselectRow:row];
    });
}

@end
