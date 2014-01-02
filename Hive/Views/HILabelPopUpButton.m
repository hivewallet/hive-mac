#import "HILabelPopUpButton.h"

@implementation HILabelPopUpButton

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self adjustPopUpButtonFont];
    }
    return self;
}


- (id)initWithFrame:(NSRect)buttonFrame pullsDown:(BOOL)flag {
    self = [super initWithFrame:buttonFrame pullsDown:flag];
    if (self) {
        [self adjustPopUpButtonFont];
    }
    return self;
}


- (void)awakeFromNib {
    [super awakeFromNib];
    [self adjustPopUpButtonFont];
}

- (void)addItemWithTitle:(NSString *)title {
    [super addItemWithTitle:title];
    [self adjustPopUpButtonFont];
}

- (void)addItemsWithTitles:(NSArray *)itemTitles {
    [super addItemsWithTitles:itemTitles];
    [self adjustPopUpButtonFont];
}

- (void)insertItemWithTitle:(NSString *)title atIndex:(NSInteger)index {
    [super insertItemWithTitle:title atIndex:index];
    [self adjustPopUpButtonFont];
}

- (void)adjustPopUpButtonFont {
    NSDictionary *attributes = @{
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:.42 alpha:1.0],
        NSFontAttributeName: [NSFont controlContentFontOfSize:12],
    };
    for (NSMenuItem *item in self.itemArray) {
        item.attributedTitle = [[NSAttributedString alloc] initWithString:item.title
                                                               attributes:attributes];
    }
}

@end
