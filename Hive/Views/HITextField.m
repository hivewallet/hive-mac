//
//  HITextField.m
//  Hive
//
//  Created by Bazyli Zygan on 04.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HITextField.h"
#import "HITextFieldCell.h"
#import "NSColor+Hive.h"

NSString * const kHITextFieldContentChanged = @"kHITextFieldContentChanged";

@interface HITextField () {
    NSView *_bgView;
    BOOL _isEmpty;
    BOOL _isFocused;
}

@end

@implementation HITextField

- (BOOL)isEmpty {
    return _isEmpty;
}

- (void)awakeFromNib {
    self.delegate = self;
    _bgView = [[NSView alloc] initWithFrame:NSMakeRect(self.frame.origin.x - 1,
                                                       self.frame.origin.y + 1,
                                                       self.frame.size.width + 2,
                                                       self.frame.size.height + 2)];
    _bgView.wantsLayer = YES;
    _bgView.layer.backgroundColor = [[NSColor whiteColor] CGColor];
    _bgView.layer.borderWidth = 1.0;
    _bgView.layer.borderColor = [[NSColor blackColor] CGColor];
    _bgView.autoresizingMask = NSViewMaxYMargin | NSViewMinXMargin;
    _bgView.layer.shadowColor = [[NSColor colorWithCalibratedWhite:0.3 alpha:1.0] CGColor];
    _bgView.layer.shadowOffset = NSMakeSize(-2, -2);
    _bgView.layer.shadowOpacity = 0.8;
    _bgView.layer.shadowRadius = 2.0;
    [_bgView setHidden:YES];
    [self.superview addSubview:_bgView positioned:NSWindowBelow relativeTo:self];
}

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        self.cell = [HITextFieldCell new];
        [self.cell setUsesSingleLineMode:YES];
        [self.cell setWraps:NO];
        [self.cell setScrollable:YES];
        self.stringValue = @"";
        [self setBordered:NO];
        [self setFocusRingType:NSFocusRingTypeNone];
        [self setEditable:YES];
        [self setEnabled:YES];
    }
    
    return self;
}

- (BOOL)becomeFirstResponder {
    BOOL become = [super becomeFirstResponder];
    if (become) {
        [_bgView setHidden:NO];
        [_bgView setNeedsDisplay:YES];
  
        if (self.stringValue.length == 0) {
            _isEmpty = YES;
            self.stringValue = [self.cell placeholderString];

            dispatch_async(dispatch_get_main_queue(), ^{
                _isFocused = YES;
                [[self currentEditor] setSelectedRange:NSMakeRange(0, self.stringValue.length)];                
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                _isFocused = YES;
            });
        }

        [self recalcForString:self.stringValue];
    }

    return become;
}

- (void)mouseDown:(NSEvent *)theEvent {
    if (_isFocused) {
        [super mouseDown:theEvent];
    }
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    _isFocused = NO;
    [_bgView setHidden:YES];

    if (_isEmpty) {
        [self setValueAndRecalc:@""];
    }
}

- (void)setValueAndRecalc:(NSString *)value {
    [self setStringValue:value];
    [self recalcForString:value];
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize {
    NSSize newSize = self.superview.bounds.size;

    [super resizeWithOldSuperviewSize:oldSize];

    if (newSize.width != oldSize.width) {
        [self recalcForString:self.stringValue];
    }
}

- (void)recalcForString:(NSString *)string {
    if (string.length == 0) {
        string = [self.cell placeholderString];
    }

    NSSize size = [string sizeWithAttributes:@{NSFontAttributeName: self.font}];
    NSRect f = self.frame;
    f.size.width = size.width + 4;
    
    NSRect sf = self.superview.bounds;
    if (f.origin.x + f.size.width - 10 > sf.size.width) {
        f.size.width = sf.size.width - f.origin.x - 10;
    }
    
    self.frame = f;
    [[NSNotificationCenter defaultCenter] postNotificationName:kHITextFieldContentChanged object:self];
}

- (void)controlTextDidChange:(NSNotification *)obj {
    [_bgView setNeedsDisplay:YES];
    [self recalcForString:self.stringValue];
    _isEmpty = (self.stringValue.length == 0);

    if (_isEmpty) {
        self.stringValue = [self.cell placeholderString];
        dispatch_async(dispatch_get_main_queue(), ^{
            _isFocused = YES;
            [[self currentEditor] setSelectedRange:NSMakeRange(0, self.stringValue.length)];
        });
    }
}

- (void)setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    _bgView.frame = NSMakeRect(self.frame.origin.x - 1,
                               self.frame.origin.y + 1,
                               self.frame.size.width + 2,
                               self.frame.size.height + 2);
}

- (BOOL)isFocused {
    return _isFocused;
}

- (NSString *)enteredValue {
    return (!_isEmpty && self.stringValue.length > 0) ? self.stringValue : nil;
}

- (void)dealloc {
    [_bgView removeFromSuperview];
}

@end
