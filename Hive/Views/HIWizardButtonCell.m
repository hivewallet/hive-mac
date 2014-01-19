#import "HIWizardButtonCell.h"

static const float PADDING_X = 20.0;
static const float PADDING_Y = 20.0;

@implementation HIWizardButtonCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.cornerRadius = 1.0;
    self.font = [NSFont fontWithName:@"Helvetica" size:16];
}

- (NSSize)cellSize {
    CGSize size = [super cellSize];
    size.width += 2 * PADDING_X;
    size.height += 2 * PADDING_Y;
    return size;
}

@end
