#import "HIEmptyTransactionsView.h"

#import "HIAddressesBox.h"
#import "HIProfile.h"

@interface HIEmptyTransactionsView ()

@property (nonatomic, strong) IBOutlet HIAddressesBox *addressesBox;

@end


@implementation HIEmptyTransactionsView

- (void)awakeFromNib {
    [super awakeFromNib];

    self.addressesBox.addresses = [HIProfile new].addresses.allObjects;
}

@end
