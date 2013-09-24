//
//  HIContactAutocompleteWindowController.h
//  Hive
//
//  Created by Jakub Suder on 20.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HIAddress;

@protocol HIContactAutocompleteDelegate

- (void)addressSelectedInAutocomplete:(HIAddress *)address;

@end

@interface HIContactAutocompleteWindowController : NSWindowController <NSTableViewDelegate>

@property (nonatomic, strong) IBOutlet NSArrayController *arrayController;
@property (nonatomic, strong) IBOutlet NSTableView *tableView;
@property (nonatomic, unsafe_unretained) id<HIContactAutocompleteDelegate> delegate;

- (void)searchWithContact:(HIContact *)contact;
- (void)searchWithQuery:(NSString *)query;

@end
