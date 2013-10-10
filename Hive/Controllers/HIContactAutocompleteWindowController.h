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


/*
 Manages the results list that appears in the "Send Bitcoin" window when user starts typing to look up a contact.
 */

@interface HIContactAutocompleteWindowController : NSWindowController <NSTableViewDelegate>

@property (nonatomic, strong) IBOutlet NSArrayController *arrayController;
@property (nonatomic, strong) IBOutlet NSTableView *tableView;
@property (nonatomic, unsafe_unretained) id<HIContactAutocompleteDelegate> delegate;

- (void)searchWithContact:(HIContact *)contact;
- (void)searchWithQuery:(NSString *)query;

@end
