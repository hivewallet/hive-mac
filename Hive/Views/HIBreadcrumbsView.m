#import "HIBreadcrumbsView.h"
#import "HIRightPointingArrowView.h"

static const double SPACING = 12;
static const double ARROW_WIDTH = 8;
static const double HEIGHT = 30;
static const int FONT_SIZE = 14;

@interface HIBreadcrumbsView ()

@property (nonatomic, copy) NSArray *labels;
@property (nonatomic, copy) NSArray *arrows;

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

    NSMutableArray *arrows = [NSMutableArray new];
    NSUInteger numArrows = self.titles.count - 1;
    for (int i = 0; i < numArrows; i++) {
        HIRightPointingArrowView *arrow = [self createArrow];
        [self addSubview:arrow];
        [arrows addObject:arrow];
    }
    self.arrows = arrows;

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

- (HIRightPointingArrowView *)createArrow {
    HIRightPointingArrowView *arrow = [HIRightPointingArrowView new];
    arrow.strokeColor = [NSColor whiteColor];
    arrow.strokeWidth = 2.0;
    arrow.translatesAutoresizingMaskIntoConstraints = NO;
    return arrow;
}

- (NSSize)intrinsicContentSize {
    double width = self.arrows.count * (ARROW_WIDTH + 2 * SPACING);
    double height = 0;
    for (NSView *subview in self.labels) {
        NSSize size = subview.intrinsicContentSize;
        width += size.width;
        height = MIN(height, size.height);
    }
    return CGSizeMake(width, HEIGHT);
}

- (void)updateConstraints {
    [self removeConstraints:self.constraints];

    [super updateConstraints];

    if (self.labels.count > 0) {
        NSView *firstLabel = self.labels.firstObject;
        [self addConstraint:INSET_LEFT(firstLabel, 0)];

        long n = self.arrows.count;
        NSAssert(self.labels.count == self.arrows.count + 1, @"Breadcrumb views don't match");
        for (long i = 0; i < n; i++) {
            NSView *label = self.labels[i];
            NSView *arrow = self.arrows[i];
            NSView *nextLabel = self.labels[i + 1];

            [arrow addConstraint:PIN_WIDTH(arrow, ARROW_WIDTH)];

            [self addConstraints:@[
                HSPACE(label, arrow, SPACING),
                INSET_TOP(arrow, 0.0),
                INSET_BOTTOM(arrow, 0.0),
                HSPACE(arrow, nextLabel, SPACING)
            ]];
        }
        for (NSView *label in self.labels) {
            [self addConstraint:ALIGN_CENTER_Y(label, self)];
        }

        NSView *lastLabel = self.labels.lastObject;
        [self addConstraint:INSET_RIGHT(lastLabel, 0)];
    }
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
