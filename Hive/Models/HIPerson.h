@class HIAddress;


/*
 A common interface for HIProfile and HIContact.
 */

@protocol HIPerson<NSObject>

@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *firstname;
@property (nonatomic, strong) NSString *lastname;
@property (nonatomic, strong) NSSet *addresses;
@property (nonatomic, strong) NSData *avatar;
@property (nonatomic, strong, readonly) NSImage *avatarImage;
@property (nonatomic, readonly) NSString *name;

- (BOOL)canBeRemoved;
- (BOOL)canEditAddresses;

- (void)addAddressesObject:(HIAddress *)value;

@end
