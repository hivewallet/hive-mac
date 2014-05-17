@interface HIObservationHandler : NSObject

@property (nonatomic, copy, readonly) NSArray *allObservers;

- (void)addObserver:(id)observer;
- (void)removeObserver:(id)observer;

@end
