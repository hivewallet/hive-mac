#import "HIObservationHandler.h"

SPEC_BEGIN(HIObservationHandlerSpec)

    __block HIObservationHandler *handler;

    beforeEach(^{
        handler = [HIObservationHandler new];
    });

    it(@"has no observers by default", ^{
        assertThat(handler.allObservers, isEmpty());
    });

    it(@"adds observers", ^{
        id observer = @"object 1";
        [handler addObserver:observer];
        assertThat(handler.allObservers, containsInAnyOrder(observer, nil));
    });

    context(@"when multiple observers were added", ^{

        id observer1 = @"object 1";
        id observer2 = @"object 2";
        id observer3 = @"object 3";

        beforeEach(^{
            [handler addObserver:observer1];
            [handler addObserver:observer2];
            [handler addObserver:observer3];
        });

        it(@"contains all observers", ^{
            assertThat(handler.allObservers,
                       containsInAnyOrder(observer1, observer2, observer3, nil));
        });

        it(@"removes observers", ^{
            [handler removeObserver:observer2];
            assertThat(handler.allObservers, containsInAnyOrder(observer1, observer3, nil));
        });
    });

    it(@"removes observers that go out of scope", ^{
        {
            id observer = [NSObject new];
            [handler addObserver:observer];
        }
        assertThat(handler.allObservers, isEmpty());
    });


SPEC_END
