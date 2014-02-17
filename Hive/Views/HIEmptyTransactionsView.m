#import "HIEmptyTransactionsView.h"

#import "HIAddressesBox.h"
#import "HIProfile.h"

@interface HIEmptyTransactionsView ()

@property (nonatomic, strong) IBOutlet HIAddressesBox *addressesBox;

@end


@implementation HIEmptyTransactionsView

- (void)awakeFromNib {
    self.addressesBox.addresses = [HIProfile new].addresses.allObjects;
    self.addressesBox.observingWallet = YES;
    self.addressesBox.showsBarcode = YES;
}

@end
