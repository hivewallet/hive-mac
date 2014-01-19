#import "HIBreadcrumbsView.h"

static const double SPACING = 30;
static const int FONT_SIZE = 14;

@interface HIBreadcrumbsView ()

@property (nonatomic, copy) NSArray *labels;

@end

@implementation HIBreadcrumbsView

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        // TODO
        self.titles = @[@"Welcome", @"Password", @"Backup"];

        [self setUpBreadcrumbs];
    }
    return self;
}

- (void)setUpBreadcrumbs {
    NSMutableArray *labels = [NSMutableArray new];
    for (NSString *title in self.titles) {
        NSTextField *label = [self createLabel];
        label.attributedStringValue = [self createLabelString:title selected:NO];
        [self addSubview:label];
        [labels addObject:label];
    }
    self.labels = labels;

    [self invalidateIntrinsicContentSize];
    [self setNeedsUpdateConstraints:YES];
}

- (NSAttributedString *)createLabelString:(NSString *)title selected:(BOOL)selected {
    return [[NSAttributedString alloc] initWithString:title attributes:@{
        NSFontAttributeName: selected ? [NSFont boldSystemFontOfSize:FONT_SIZE] : [NSFont systemFontOfSize:FONT_SIZE],
    }];
}

- (NSTextField *)createLabel {
    NSTextField *label = [NSTextField new];
    label.textColor = [NSColor whiteColor];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.editable = NO;
    label.drawsBackground = NO;
    label.bordered = NO;
    return label;
}

- (NSSize)intrinsicContentSize {
    double width = (self.labels.count - 1) * SPACING;
    double height = 0;
    for (NSView *subview in self.labels) {
        NSSize size = subview.intrinsicContentSize;
        width += size.width;
        height = MIN(height, size.height);
    }
    return CGSizeMake(width, 60);
}

- (void)updateConstraints {
    [self removeConstraints:self.constraints];

    [super updateConstraints];

    NSView *last = nil;
    for (NSView *label in self.labels) {
        if (last) {
            [self addConstraint:HSPACE(last, label, SPACING)];
        } else {
            [self addConstraint:INSET_LEFT(label, 0)];
        }
        [self addConstraint:ALIGN_CENTER_Y(label, self)];
        last = label;
    }
    [self addConstraint:INSET_RIGHT(last, 0)];
}

- (void)layoutSubtreeIfNeeded {
    [super layoutSubtreeIfNeeded];
}

- (void)viewDidMoveToSuperview {
    [super viewDidMoveToSuperview];
}

- (void)setActiveIndex:(int)activeIndex {
    [self updateLabelAtIndex:_activeIndex selected:NO];
    _activeIndex = activeIndex;
    [self updateLabelAtIndex:_activeIndex selected:YES];
}

- (void)updateLabelAtIndex:(int)index selected:(BOOL)selected {
    NSTextField *label = self.labels[index];
    label.attributedStringValue = [self createLabelString:self.titles[index] selected:selected];
}

@end
