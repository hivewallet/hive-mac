//
//  HITextField.h
//  Hive
//
//  Created by Bazyli Zygan on 04.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

extern NSString * const kHITextFieldContentChanged;

/*
 A version of NSTextField that resizes itself to match the content size. Used for inline edit fields in contact
 form (first name, last name, etc.).
 */

@interface HITextField : NSTextField <NSTextFieldDelegate>

@property (nonatomic, readonly) BOOL isEmpty;
@property (nonatomic, readonly) BOOL isFocused;

- (void)recalcForString:(NSString *)string;
- (void)setValueAndRecalc:(NSString *)value;
- (NSString *)enteredValue;

@end
