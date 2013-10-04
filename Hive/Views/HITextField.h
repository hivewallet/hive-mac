//
//  HITextField.h
//  Hive
//
//  Created by Bazyli Zygan on 04.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const kHITextFieldContentChanged;

@interface HITextField : NSTextField <NSTextFieldDelegate>

@property (readonly, nonatomic, getter = isEmpty) BOOL isEmpty;
@property (readonly, nonatomic, getter = isFocused) BOOL isFocused;

- (void)recalcForString:(NSString *)string;
- (void)setValueAndRecalc:(NSString *)value;
- (NSString *)enteredValue;

@end
