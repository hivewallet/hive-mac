@class HIAddress;


/*
 A common interface for HIProfile and HIContact.
 */

@protocol HIPerson<NSObject>

@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *firstname;
@property (nonatomic, copy) NSString *lastname;
@property (nonatomic, copy) NSSet *addresses;
@property (nonatomic, copy) NSData *avatar;
@property (nonatomic, strong, readonly) NSImage *avatarImage;
@property (nonatomic, copy, readonly) NSString *name;

- (BOOL)canBeRemoved;
- (BOOL)canEditAddresses;

- (void)addAddressesObject:(HIAddress *)value;

@end
