//
//  HIContactAutocompleteCellView.m
//  Hive
//
//  Created by Jakub Suder on 20.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIContactAutocompleteCellView.h"

@interface HIContactAutocompleteCellView()

@property (nonatomic, weak) IBOutlet NSTextField *addressLabel;

@end

@implementation HIContactAutocompleteCellView

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
    if (backgroundStyle == NSBackgroundStyleDark) {
        self.addressLabel.textColor = [NSColor colorWithCalibratedWhite:0.75 alpha:1.0];
    } else {
        self.addressLabel.textColor = [NSColor colorWithCalibratedWhite:0.435 alpha:1.0];
    }

    [super setBackgroundStyle:backgroundStyle];
}

@end
