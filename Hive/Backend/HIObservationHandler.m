#import "HIObservationHandler.h"

@interface HIObservationHandler()

@property (nonatomic, strong) NSHashTable *observers;

@end

@implementation HIObservationHandler

- (id)init {
    self = [super init];
    if (self) {
        _observers = [[NSHashTable alloc] initWithOptions:NSHashTableWeakMemory capacity:4];
    }
    return self;
}

- (NSArray *)allObservers {
    return _observers.allObjects;
}

- (void)addObserver:(id)observer {
    [self.observers addObject:observer];
}

- (void)removeObserver:(id)observer {
    [self.observers removeObject:observer];
}

@end
