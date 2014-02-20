//
//  HITransactionsViewController.m
//  Hive
//
//  Created by Bazyli Zygan on 28.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "BCClient.h"
#import "HIAddress.h"
#import "HIBitcoinFormatService.h"
#import "HIContact.h"
#import "HIContactRowView.h"
#import "HIDatabaseManager.h"
#import "HITransaction.h"
#import "HITransactionCellView.h"
#import "HITransactionsViewController.h"
#import "NSColor+Hive.h"

@interface HITransactionsViewController () <BCTransactionObserver>

@property (strong, nonatomic) IBOutlet NSView *noTransactionsView;
@property (strong, nonatomic) IBOutlet NSScrollView *scrollView;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet NSTableView *tableView;

@end

@implementation HITransactionsViewController {
    HIContact *_contact;
    NSDateFormatter *_transactionDateFormatter, *_fullTransactionDateFormatter;
    NSFont *_amountLabelFont;
}

- (id)init {
    self = [super initWithNibName:@"HITransactionsViewController" bundle:nil];

    if (self) {
        self.title = NSLocalizedString(@"Transactions", @"Transactions view title");
        self.iconName = @"timeline";

        _transactionDateFormatter = [NSDateFormatter new];
        _transactionDateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"LLL d jj:mm a"
                                                                               options:0
                                                                                locale:[NSLocale  currentLocale]];

        _fullTransactionDateFormatter = [NSDateFormatter new];
        _fullTransactionDateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"LLL d YYYY jj:mm a"
                                                                                   options:0
                                                                                    locale:[NSLocale  currentLocale]];

        _amountLabelFont = [NSFont fontWithName:@"Helvetica Bold" size:13.0];
    }

    return self;
}

- (id)initWithContact:(HIContact *)contact {
    self = [self init];

    if (self) {
        _contact = contact;
    }

    return self;
}

- (void) loadView {
    [super loadView];

    self.arrayController.managedObjectContext = DBM;
    self.arrayController.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];

    if (_contact) {
        self.arrayController.fetchPredicate = [NSPredicate predicateWithFormat:@"contact = %@", _contact];
    }
    [self.arrayController prepareContent];

    [self.noTransactionsView setFrame:self.view.bounds];
    [self.noTransactionsView setHidden:YES];
    [self.noTransactionsView.layer setBackgroundColor:[[NSColor hiWindowBackgroundColor] hiNativeColor]];
    [self.view addSubview:self.noTransactionsView];

    [self.arrayController addObserver:self
                           forKeyPath:@"arrangedObjects.@count"
                              options:NSKeyValueObservingOptionInitial
                              context:NULL];

    [[BCClient sharedClient] addTransactionObserver:self];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateBitcoinFormat:)
                                                 name:HIPreferredFormatChangeNotification
                                               object:nil];
}

- (void)dealloc {
    [self.arrayController removeObserver:self forKeyPath:@"arrangedObjects.@count"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[BCClient sharedClient] removeTransactionObserver:self];

    _tableView.delegate = nil;
    _tableView.dataSource = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (object == self.arrayController) {
        [self updateNoTransactionsView];
    }
}

- (void)viewWillAppear {
    [self markAllTransactionsAsRead];
}

- (void)markAllTransactionsAsRead {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HITransactionEntity];
    request.predicate = [NSPredicate predicateWithFormat:@"read = NO"];
    for (HITransaction *transaction in [DBM executeFetchRequest:request error:NULL]) {
        transaction.read = YES;
    }

    [DBM save:nil];

    [[BCClient sharedClient] updateNotifications];
}

- (void)updateNoTransactionsView {
    // don't take count from arrangedObjects because array controller might not have fetched data yet
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HITransactionEntity];
    NSUInteger count = [DBM countForFetchRequest:request error:NULL];

    BOOL shouldShowTransactions = _contact || count > 0;
    [self.noTransactionsView setHidden:shouldShowTransactions];
    [self.scrollView setHidden:!shouldShowTransactions];
}


#pragma mark - Bitcoin format

- (void)updateBitcoinFormat:(NSNotification *)notification {
    [self.tableView reloadData];
}


#pragma mark - BCTransactionObserver

- (void)transactionChangedStatus:(HITransaction *)transaction {
    NSArray *list = self.arrayController.arrangedObjects;
    NSInteger position = [list indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [[obj id] isEqual:transaction.id];
    }];

    if (position != NSNotFound) {
        [list[position] setStatus:transaction.status];
        [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:position]
                                  columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
}


#pragma mark - NSTableViewDelegate

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    return [HIContactRowView new];
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {

    // cache some objects for optimization
    static dispatch_once_t onceToken;
    static BOOL sharingSupported;
    static NSImage *plusImage, *minusImage, *btcImage;
    static NSColor *pendingColor, *cancelledColor;

    dispatch_once(&onceToken, ^{
        sharingSupported = self.sharingSupported;
        plusImage = [NSImage imageNamed:@"icon-transactions-plus"];
        minusImage = [NSImage imageNamed:@"icon-transactions-minus"];
        btcImage = [NSImage imageNamed:@"icon-transactions-btc-symbol"];
        pendingColor = [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
        cancelledColor = [NSColor redColor];
    });

    HITransactionCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    HITransaction *transaction = self.arrayController.arrangedObjects[row];

    cell.shareText = sharingSupported ? [self createShareTextForTransaction:transaction] : nil;
    cell.textField.attributedStringValue = [self summaryTextForTransaction:transaction];
    cell.dateLabel.stringValue = [self dateTextForTransaction:transaction];
    cell.directionMark.image = transaction.isIncoming ? plusImage : minusImage;

    if (transaction.contact && transaction.contact.avatarImage) {
        cell.imageView.image = transaction.contact.avatarImage;
        cell.imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    } else {
        cell.imageView.image = btcImage;
        cell.imageView.imageScaling = NSImageScaleProportionallyDown;
    }

    switch (transaction.status) {
        case HITransactionStatusBuilding:
            [cell.pendingLabel setHidden:YES];
            break;

        case HITransactionStatusDead:
            [cell.pendingLabel setHidden:NO];
            cell.pendingLabel.stringValue = NSLocalizedString(@"CANCELLED", @"Dead transaction label");
            cell.pendingLabel.textColor = cancelledColor;
            break;

        default:
            [cell.pendingLabel setHidden:NO];
            cell.pendingLabel.stringValue = NSLocalizedString(@"PENDING", @"Pending transaction label");
            cell.pendingLabel.textColor = pendingColor;
            break;
    }

    return cell;
}

- (BOOL)sharingSupported {
    return NSClassFromString(@"NSSharingServicePicker") != nil;
}

- (NSAttributedString *)createShareTextForTransaction:(HITransaction *)transaction {
    // TODO: Actually add something transaction specific?
    static NSAttributedString *sentString = nil, *receivedString = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        NSString *link = @" http://hivewallet.com";

        NSString *text = NSLocalizedString(@"I've just sent some Bitcoin using Hive",
                                           @"Share sent transaction text");
        sentString = [[NSAttributedString alloc] initWithString:[text stringByAppendingString:link]];

        text = NSLocalizedString(@"I've just received some Bitcoin using Hive",
                                 @"Share sent transaction text");
        receivedString = [[NSAttributedString alloc] initWithString:[text stringByAppendingString:link]];
    });

    return (transaction.isIncoming ? receivedString : sentString);
}

- (NSAttributedString *)summaryTextForTransaction:(HITransaction *)transaction {
    NSString *text;

    // not using standard localized string variables on purpose because we need to mark the fragments with bold
    if (transaction.isIncoming) {
        if (transaction.contact) {
            text = NSLocalizedString(@"Received &a from &c", @"Received amount of BTC from contact");
        } else {
            text = NSLocalizedString(@"Received &a", @"Received amount of BTC from unknown source");
        }
    } else {
        text = NSLocalizedString(@"Sent &a to &c", @"Sent amount of BTC to a contact/address");
    }

    // The attribute in IB does not work for attributed strings.
    NSMutableParagraphStyle *truncatingStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    truncatingStyle.lineBreakMode = NSLineBreakByTruncatingTail;

    NSDictionary *attributes = @{NSParagraphStyleAttributeName: truncatingStyle};
    NSDictionary *boldAttributes = @{NSFontAttributeName: _amountLabelFont,
                                     NSParagraphStyleAttributeName: truncatingStyle};

    NSMutableAttributedString *summary = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];

    NSRange amountRange = [summary.string rangeOfString:@"&a"];
    if (amountRange.location != NSNotFound) {
        satoshi_t satoshi = transaction.absoluteAmount;
        NSString *value = [[HIBitcoinFormatService sharedService] stringWithUnitForBitcoin:satoshi];
        NSAttributedString *fragment = [[NSAttributedString alloc] initWithString:value attributes:boldAttributes];
        [summary replaceCharactersInRange:amountRange withAttributedString:fragment];
    }

    NSRange contactRange = [summary.string rangeOfString:@"&c"];
    if (contactRange.location != NSNotFound) {
        NSString *value;

        if (transaction.contact.firstname.length > 0) {
            value = transaction.contact.firstname;
        } else if (transaction.contact.lastname.length > 0) {
            value = transaction.contact.lastname;
        } else if (contactRange.location == summary.string.length - 2) {
            value = transaction.senderHash;
        } else {
            // we can't tail-truncate if the address is not at the end, so we'll truncate it manually
            value = [NSString stringWithFormat:@"%@…%@",
                     [transaction.senderHash substringToIndex:8],
                     [transaction.senderHash substringFromIndex:(transaction.senderHash.length - 8)]];
        }

        NSAttributedString *fragment = [[NSAttributedString alloc] initWithString:value attributes:boldAttributes];
        [summary replaceCharactersInRange:contactRange withAttributedString:fragment];
    }

    return summary;
}

- (NSString *)dateTextForTransaction:(HITransaction *)transaction {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger currentYear = [[calendar components:NSYearCalendarUnit fromDate:[NSDate date]] year];
    NSInteger transactionYear = [[calendar components:NSYearCalendarUnit fromDate:transaction.date] year];

    if (currentYear == transactionYear) {
        return [_transactionDateFormatter stringFromDate:transaction.date];
    } else {
        return [_fullTransactionDateFormatter stringFromDate:transaction.date];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) {
        return;
    }

    [self.tableView deselectRow:row];
}

@end
