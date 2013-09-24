//
//  HIContactCellView.m
//  Hive
//
//  Created by Jakub Suder on 29.08.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIContactCellView.h"
#import "HIContact.h"
@interface HIContactCellView ()

@end

@implementation HIContactCellView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];

    if (self) {

    }
    
    return self;
}


- (void)setObjectValue:(id)objectValue
{
    [super setObjectValue:objectValue];
    HIContact *c = (HIContact *)objectValue;
    
    self.imageView.image = c.avatarImage;
    self.textField.stringValue = c.name;
}

//- (void)drawRect:(NSRect)dirtyRect {
//}

@end
