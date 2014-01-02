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
#import "HIDatabaseManager.h"
#import "HITransaction.h"
#import "HITransactionCellView.h"
#import "HITransactionsViewController.h"
#import "NSColor+Hive.h"
#import "HIBitcoinFormatService.h"

@interface HITransactionsViewController ()

@property (strong, nonatomic) IBOutlet NSView *noTransactionsView;
@property (strong, nonatomic) IBOutlet NSScrollView *scrollView;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet NSTableView *tableView;

@end

@implementation HITransactionsViewController {
    HIContact *_contact;
    NSDateFormatter *_transactionDateFormatter;
    NSFont *_amountLabelFont;
}

- (id)init {
    self = [super initWithNibName:@"HITransactionsViewController" bundle:nil];

    if (self) {
        self.title = NSLocalizedString(@"Transactions", @"Transactions view title");
        self.iconName = @"timeline";

        _transactionDateFormatter = [NSDateFormatter new];
        _transactionDateFormatter.dateFormat = @"LLL d";

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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateBitcoinFormat:)
                                                 name:HIPreferredFormatChangeNotification
                                               object:nil];
}

- (void)dealloc {
    [self.arrayController removeObserver:self forKeyPath:@"arrangedObjects.@count"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

#pragma mark - bitcoin format

- (void)updateBitcoinFormat:(NSNotification *)notification {
    [self.tableView reloadData];
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
    cell.dateLabel.stringValue = [_transactionDateFormatter stringFromDate:transaction.date];
    cell.directionMark.image = (transaction.direction == HITransactionDirectionIncoming) ? plusImage : minusImage;

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
    static NSAttributedString *string = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *raw = NSLocalizedString(@"I just sent some Bitcoin using Hive", @"Share transaction template text");
        NSMutableAttributedString *mutableString = [[NSMutableAttributedString alloc] initWithString:raw];
        [mutableString addAttribute:NSLinkAttributeName
                              value:[NSURL URLWithString:@"http://hivewallet.com"]
                              range:[raw rangeOfString:@"Hive"]];
        string = mutableString;
    });
    return string;
}

- (NSAttributedString *)summaryTextForTransaction:(HITransaction *)transaction {
    NSString *amountPart =
        [[HIBitcoinFormatService sharedService] stringWithDesignatorForBitcoin:transaction.absoluteAmount];

    NSString *directionPart = (transaction.direction == HITransactionDirectionIncoming) ?
        NSLocalizedString(@"from", @"Direction label in transactions list when user is the receiver") :
        NSLocalizedString(@"to", @"Direction label in transactions list when user is the sender");

    NSString *contactPart = transaction.contact ? transaction.contact.firstname : transaction.senderHash;

    NSString *text = [NSString stringWithFormat:@"%@ %@ %@", amountPart, directionPart, contactPart];

    // The attribute in IB does not work for attributed strings.
    NSMutableParagraphStyle *truncatingStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    truncatingStyle.lineBreakMode = NSLineBreakByTruncatingTail;

    NSMutableAttributedString *summary =
        [[NSMutableAttributedString alloc] initWithString:text
                                               attributes:@{NSParagraphStyleAttributeName: truncatingStyle}];

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
