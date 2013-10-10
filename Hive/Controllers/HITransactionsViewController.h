//
//  HITransactionsViewController.h
//  Hive
//
//  Created by Bazyli Zygan on 28.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIViewController.h"

/*
 Manages the transactions list view.
 */

@interface HITransactionsViewController : HIViewController

@property (strong, nonatomic) IBOutlet NSView *noTransactionsView;
@property (strong, nonatomic) IBOutlet NSScrollView *scrollView;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet NSTableView *tableView;

- (id)initWithContact:(HIContact *)contact;

@end
