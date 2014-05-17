@protocol HIPerson;
@protocol HINameFormatServiceObserver;

@interface HINameFormatService : NSObject

+ (instancetype)sharedService;

- (void)addObserver:(id<HINameFormatServiceObserver>)observer;
- (void)removeObserver:(id<HINameFormatServiceObserver>)observer;

- (NSString *)fullNameForPerson:(id<HIPerson>)person;

@end

@protocol HINameFormatServiceObserver<NSObject>

- (void)nameFormatDidChange;

@end
