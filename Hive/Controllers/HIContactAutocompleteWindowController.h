//
//  HIContactAutocompleteWindowController.h
//  Hive
//
//  Created by Jakub Suder on 20.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

@class HIAddress;

@protocol HIContactAutocompleteDelegate

- (void)addressSelectedInAutocomplete:(HIAddress *)address;

@end


/*
 Manages the results list that appears in the "Send Bitcoin" window when user starts typing to look up a contact.
 */

@interface HIContactAutocompleteWindowController : NSWindowController <NSTableViewDelegate>

@property (nonatomic, weak) id<HIContactAutocompleteDelegate> delegate;

- (void)searchWithContact:(HIContact *)contact;
- (void)searchWithQuery:(NSString *)query;

- (void)moveSelectionUp;
- (void)moveSelectionDown;
- (void)confirmSelection;

- (IBAction)tableRowClicked:(id)sender;

@end
