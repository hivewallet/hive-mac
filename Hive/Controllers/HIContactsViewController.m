//
//  HIContactsViewController.m
//  Hive
//
//  Created by Bazyli Zygan on 28.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIContact.h"
#import "HIContactCellView.h"
#import "HIContactsViewController.h"
#import "HINavigationController.h"
#import "HIProfileViewController.h"
#import "HIContactRowView.h"
#import "HINewContactViewController.h"

static NSString *DetailsCell = @"Details";

@interface HIContactsViewController () 

@end

@implementation HIContactsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self)
    {
        self.title = NSLocalizedString(@"Contacts", @"Contacts view title");
        self.iconName = @"group";

    }
    
    return self;
}

- (NSView *)rightNavigationView
{
    return _navigationView;
}

- (IBAction)newContactClicked:(NSButton *)sender
{
    [self.navigationController pushViewController:[HINewContactViewController new] animated:YES];
}

- (NSManagedObjectContext *)managedObjectContext
{
    return DBM;
}

- (NSArray *)sortDescriptors
{
    return @[[NSSortDescriptor sortDescriptorWithKey:@"lastname" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"firstname" ascending:YES]];
}

#pragma mark - NSTableViewDataSource




#pragma mark - NSTableViewDelegate

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    return [HIContactRowView new];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) {
        return;
    }

    HIContactCellView *cell = [self.tableView viewAtColumn:0 row:row makeIfNecessary:NO];
    [cell setNeedsDisplay:YES];

    dispatch_async(dispatch_get_main_queue(), ^{
        HIViewController *sub = [[HIProfileViewController alloc] initWithContact:_arrayController.arrangedObjects[row]];
        
        [self.navigationController pushViewController:sub animated:YES];

        [self.tableView deselectRow:row];
    });
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {

    if ([tableColumn.identifier isEqual:DetailsCell])
    {
        HIContactCellView *cell = [tableView makeViewWithIdentifier:DetailsCell owner:self];
        HIContact * c = _arrayController.arrangedObjects[row];

        cell.imageView.image = c.avatarImage;
        cell.textField.stringValue = c.name;

        return cell;
    }

    return nil;
}


@end
