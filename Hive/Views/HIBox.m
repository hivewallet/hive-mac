//
//  HIBox.m
//  Hive
//
//  Created by Bazyli Zygan on 05.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIBox.h"

#import "NSColor+Hive.h"

@implementation HIBox

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpBox];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setUpBox];
}

- (void)setUpBox {
    [self setWantsLayer:YES];

    // Workaround missing layer on 10.7
    self.layer = [CALayer new];

    self.layer.borderWidth = 1.0;
    self.layer.cornerRadius = 5.0;
    self.layer.borderColor = [RGB(195,195,195) CGColor];
    self.layer.backgroundColor = [[NSColor whiteColor] CGColor];
}

@end
