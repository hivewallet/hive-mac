//
//  HILockScreenView.m
//  Hive
//
//  Created by Jakub Suder on 24/02/14.
//  Copyright (c) 2014 Hive Developers. All rights reserved.
//

#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory+OSX.h>
#import "HILockScreenView.h"

@interface HILockScreenView () {
    NSColor *backgroundPattern;
}

@property (nonatomic, strong) IBOutlet NSImageView *lockIcon;

@end

@implementation HILockScreenView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        backgroundPattern = [NSColor colorWithPatternImage:[NSImage imageNamed:@"honey_im_subtle"]];
    }

    return self;
}

- (void)awakeFromNib {
    NIKFontAwesomeIconFactory *factory = [[NIKFontAwesomeIconFactory alloc] init];
    factory.size = self.lockIcon.frame.size.width;
    self.lockIcon.image = [factory createImageForIcon:NIKFontAwesomeIconLock];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    [backgroundPattern setFill];
    NSRectFill(dirtyRect);
}

@end
