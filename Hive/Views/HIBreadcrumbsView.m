#import "HIBreadcrumbsView.h"

static const double SPACING = 30;

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
        label.stringValue = title;
        [self addSubview:label];
        [labels addObject:label];
    }
    self.labels = labels;

    [self invalidateIntrinsicContentSize];
    [self setNeedsUpdateConstraints:YES];
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

@end
