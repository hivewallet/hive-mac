#import "HIWizardSmallButtonCell.h"

static const float PADDING_X = 5;
static const float PADDING_Y = 5;

@implementation HIWizardSmallButtonCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.cornerRadius = 1.0;
    self.font = [NSFont fontWithName:@"Helvetica" size:13];
}

- (NSSize)cellSize {
    CGSize size = [super cellSize];
    size.width += 2 * PADDING_X;
    size.height += 2 * PADDING_Y;
    return size;
}

@end
