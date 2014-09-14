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
#import "HIDatabaseManager.h"
#import "HINavigationController.h"
#import "HINewContactViewController.h"
#import "NSColor+Hive.h"
#import "HINameFormatService.h"

@interface HIContactsViewController()<HINameFormatServiceObserver>

// top-level objects
@property (strong) IBOutlet NSView *navigationView;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet NSView *foreverAloneScreen;

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSScrollView *scrollView;

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, copy) NSArray *sortDescriptors;
@property (nonatomic, assign) BOOL sortByLastName;

- (IBAction)newContactClicked:(NSButton *)sender;

@end

@implementation HIContactsViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onLocaleChange)
                                                 name:NSCurrentLocaleDidChangeNotification
                                               object:nil];
    [self bind:@"sortByLastName"
      toObject:[NSUserDefaults standardUserDefaults]
   withKeyPath:@"SortByLastName"
       options:nil];
    [self updateSortDescriptors];
}

- (void)viewWillAppear {
    [self.arrayController rearrangeObjects];
    [[HINameFormatService sharedService] addObserver:self];
}

- (void)viewWillDisappear {
    [[HINameFormatService sharedService] removeObserver:self];
}

- (void)dealloc {
    [self unbind:@"sortByLastName"];
    [self.arrayController removeObserver:self forKeyPath:@"arrangedObjects.@count"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    _tableView.delegate = nil;
    _tableView.dataSource = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (object == self.arrayController) {
        [self updateForeverAloneScreen];
    }
}

- (void)onLocaleChange {
    [self.arrayController rearrangeObjects];
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

- (void)setSortByLastName:(BOOL)sortByLastName {
    _sortByLastName = sortByLastName;
    [self updateSortDescriptors];
}

- (void)updateSortDescriptors {
    NSSortDescriptor *lastName =
        [NSSortDescriptor sortDescriptorWithKey:@"lastname"
                                      ascending:YES
                                       selector:@selector(localizedStandardCompare:)];
    NSSortDescriptor *firstName =
        [NSSortDescriptor sortDescriptorWithKey:@"firstname"
                                      ascending:YES
                                       selector:@selector(localizedStandardCompare:)];
    self.sortDescriptors = self.sortByLastName ? @[lastName, firstName] : @[firstName, lastName];
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
    });
}

#pragma mark - HINameFormatServiceObserver

- (void)nameFormatDidChange {
    [self.arrayController rearrangeObjects];
}

@end
