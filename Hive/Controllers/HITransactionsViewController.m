//
//  HITransactionsViewController.m
//  Hive
//
//  Created by Bazyli Zygan on 28.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HIAddress.h"
#import "HIContact.h"
#import "HIContactRowView.h"
#import "HITransaction.h"
#import "HITransactionCellView.h"
#import "HITransactionsViewController.h"

@interface HITransactionsViewController () {
    HIContact *_contact;
    NSDateFormatter *_transactionDateFormatter;
    NSNumberFormatter *_amountFormatter;
    NSFont *_amountLabelFont;
}

@end

@implementation HITransactionsViewController

- (id)init
{
    self = [super initWithNibName:@"HITransactionsViewController" bundle:nil];

    if (self)
    {
        self.title = NSLocalizedString(@"Transactions", @"Transactions view title");
        self.iconName = @"timeline";

        _transactionDateFormatter = [NSDateFormatter new];
        _transactionDateFormatter.dateFormat = @"LLL d";

        _amountFormatter = [[NSNumberFormatter alloc] init];
        _amountFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        _amountFormatter.localizesFormat = YES;

        _amountLabelFont = [NSFont fontWithName:@"Helvetica Bold" size:13.0];
    }

    return self;
}

- (id)initWithContact:(HIContact *)contact
{
    self = [self init];

    if (self)
    {
        _contact = contact;
    }

    return self;
}

- (void) loadView
{
    [super loadView];

    self.arrayController.managedObjectContext = DBM;
    self.arrayController.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];

    if (_contact)
    {
        self.arrayController.fetchPredicate = [NSPredicate predicateWithFormat:@"contact = %@", _contact];
    }
}

- (void)viewWillAppear
{
    for (HITransaction *transaction in self.arrayController.arrangedObjects)
    {
        if (!transaction.read)
        {
            transaction.read = YES;
        }
    }

    [DBM save:nil];

    [[BCClient sharedClient] updateNotifications];
}


#pragma mark - NSTableViewDelegate

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    return [HIContactRowView new];
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {

    HITransactionCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    HITransaction *transaction = self.arrayController.arrangedObjects[row];

    cell.textField.attributedStringValue = [self summaryTextForTransaction:transaction];
    cell.dateLabel.stringValue = [_transactionDateFormatter stringFromDate:transaction.dateObject];

    if (transaction.direction == HITransactionDirectionIncoming)
    {
        cell.directionMark.image = [NSImage imageNamed:@"icon-transactions-plus"];
    }
    else
    {
        cell.directionMark.image = [NSImage imageNamed:@"icon-transactions-minus"];
    }

    if (transaction.contact && transaction.contact.avatarImage)
    {
        cell.imageView.image = transaction.contact.avatarImage;
        cell.imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    }
    else
    {
        cell.imageView.image = [NSImage imageNamed:@"icon-transactions-btc-symbol"];
        cell.imageView.imageScaling = NSImageScaleProportionallyDown;
    }

    return cell;
}

- (NSAttributedString *)summaryTextForTransaction:(HITransaction *)transaction
{
    NSString *formattedAmount = [_amountFormatter stringFromNumber:@(transaction.absoluteAmount * 1.0 / SATOSHI)];
    NSString *amountPart = [NSString stringWithFormat:@"%@ BTC", formattedAmount];
    NSString *directionPart = (transaction.direction == HITransactionDirectionIncoming) ? @"from" : @"to";

    // TODO: dynamic truncation and styling for hashes
    NSString *contactPart;
    if (transaction.contact)
    {
        contactPart = transaction.contact.firstname;
    }
    else
    {
        contactPart = [HIAddress truncateAddress:transaction.senderHash];
    }

    NSString *text = [NSString stringWithFormat:@"%@ %@ %@", amountPart, directionPart, contactPart];
    NSMutableAttributedString *summary = [[NSMutableAttributedString alloc] initWithString:text];

    [summary addAttribute:NSFontAttributeName
                    value:_amountLabelFont
                    range:NSMakeRange(0, amountPart.length)];
    [summary addAttribute:NSFontAttributeName
                    value:_amountLabelFont
                    range:NSMakeRange(amountPart.length + directionPart.length + 2, contactPart.length)];

    return summary;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) {
        return;
    }

    [self.tableView deselectRow:row];
}

@end
