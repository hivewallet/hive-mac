#import "HIBitcoinFormatService.h"

@interface NSObject()
- (void)receiveNotification:(NSNotification *)notification;
@end

SPEC_BEGIN(HIBitcoinFormatServiceSpec)

describe(@"Formatting", ^{

    __block HIBitcoinFormatService *service;

    beforeEach(^{
        service = [HIBitcoinFormatService new];
        service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    });

    context(@"preferred format is BTC", ^{
        beforeEach(^{
            service.preferredFormat = @"BTC";
        });
        it(@"formats using the preferred format", ^{
            NSString *string = [service stringForBitcoin:60000000];
            assertThat(string, equalTo(@"0.60"));
        });
        it(@"adds the correct unit", ^{
            NSString *string = [service stringWithUnitForBitcoin:60000000];
            assertThat(string, equalTo(@"0.60 BTC"));
        });
    });

    context(@"preferred format is mBTC", ^{
        beforeEach(^{
            service.preferredFormat = @"mBTC";
        });
        it(@"formats using the preferred format", ^{
            NSString *string = [service stringForBitcoin:160000];
            assertThat(string, equalTo(@"1.6"));
        });
        it(@"adds the correct unit", ^{
            NSString *string = [service stringWithUnitForBitcoin:160000];
            assertThat(string, equalTo(@"1.6 mBTC"));
        });
    });

    context(@"preferred format is µBTC", ^{
        beforeEach(^{
            service.preferredFormat = @"µBTC";
        });
        it(@"formats using the preferred format", ^{
            NSString *string = [service stringForBitcoin:160];
            assertThat(string, equalTo(@"1.6"));
        });
        it(@"adds the correct unit", ^{
            NSString *string = [service stringWithUnitForBitcoin:160];
            assertThat(string, equalTo(@"1.6 µBTC"));
        });
    });

    context(@"formatting as BTC", ^{
        it(@"adds the minimum number of decimal places", ^{
            NSString *string = [service stringForBitcoin:60000000 withFormat:@"BTC"];
            assertThat(string, equalTo(@"0.60"));
        });
        it(@"keeps all required decimal places", ^{
            NSString *string = [service stringForBitcoin:123456789 withFormat:@"BTC"];
            assertThat(string, equalTo(@"1.23456789"));
        });
        it(@"formats negative values correcly", ^{
            NSString *string = [service stringForBitcoin:-60000000 withFormat:@"BTC"];
            assertThat(string, equalTo(@"-0.60"));
        });
    });

    context(@"formatting as mBTC", ^{
        it(@"formats value correcly", ^{
            NSString *string = [service stringForBitcoin:160000 withFormat:@"mBTC"];
            assertThat(string, equalTo(@"1.6"));
        });
    });

    context(@"formatting as µBTC", ^{
        it(@"formats value correcly", ^{
            NSString *string = [service stringForBitcoin:160 withFormat:@"µBTC"];
            assertThat(string, equalTo(@"1.6"));
        });
    });

    context(@"formatting as satoshi", ^{
        it(@"formats value correcly", ^{
            NSString *string = [service stringForBitcoin:60 withFormat:@"satoshi"];
            assertThat(string, equalTo(@"60"));
        });
    });

    context(@"using a different locale", ^{
        it(@"formats value correcly", ^{
            service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
            NSString *string = [service stringForBitcoin:100060000000 withFormat:@"BTC"];
            assertThat(string, equalTo(@"1.000,60"));
        });
    });
});

describe(@"Parsing", ^{

    __block HIBitcoinFormatService *service;

    beforeEach(^{
        service = [HIBitcoinFormatService new];
        service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    });

    it(@"should parse BTC value correctly", ^{
        satoshi_t amount = [service parseString:@"0.6" withFormat:@"BTC" error:NULL];
        assertThat(@(amount), equalToLongLong(60000000));
    });

    it(@"should parse mBTC value correctly", ^{
        satoshi_t amount = [service parseString:@"0.6" withFormat:@"mBTC" error:NULL];
        assertThat(@(amount), equalToLongLong(60000));
    });

    it(@"should parse µBTC value correctly", ^{
        satoshi_t amount = [service parseString:@"0.6" withFormat:@"µBTC" error:NULL];
        assertThat(@(amount), equalToLongLong(60));
    });

    it(@"should parse satoshi value correctly", ^{
        satoshi_t amount = [service parseString:@"60" withFormat:@"satoshi" error:NULL];
        assertThat(@(amount), equalToLongLong(60));
    });

    it(@"should parse string without leading zero correctly", ^{
        satoshi_t amount = [service parseString:@".60" withFormat:@"BTC" error:NULL];
        assertThat(@(amount), equalToLongLong(60000000));
    });

    it(@"should parse string with thousands separator correctly", ^{
        satoshi_t amount = [service parseString:@"1,000.6" withFormat:@"BTC" error:NULL];
        assertThat(@(amount), equalToLongLong(100060000000));
    });

    it(@"should parse negative string correctly", ^{
        satoshi_t amount = [service parseString:@"-0.6" withFormat:@"BTC" error:NULL];
        assertThat(@(amount), equalToLongLong(-60000000));
    });

    context(@"using a different locale", ^{
        it(@"should parse value correctly", ^{
            service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
            satoshi_t amount = [service parseString:@"1.000,6" withFormat:@"BTC" error:NULL];
            assertThat(@(amount), equalToLongLong(100060000000));
        });
        it(@"should parse value with spaces correctly", ^{
            service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"sv_SE"];
            satoshi_t amount = [service parseString:@"1 000,6" withFormat:@"BTC" error:NULL];
            assertThat(@(amount), equalToLongLong(100060000000));
        });
    });

    context(@"parsing illegal string", ^{
        context(@"error variable is set", ^{
            it(@"should return 0", ^{
                NSError *error;
                satoshi_t amount = [service parseString:@"xx" withFormat:@"BTC" error:&error];
                assertThat(@(amount), equalToLongLong(0));
            });
            it(@"should set error", ^{
                NSError *error;
                [service parseString:@"xx" withFormat:@"BTC" error:&error];
                assertThat(error, notNilValue());
            });
        });
        context(@"error variable is NULL", ^{
            it(@"should return 0", ^{
                satoshi_t amount = [service parseString:@"xx" withFormat:@"BTC" error:NULL];
                assertThat(@(amount), equalToLongLong(0));
            });
        });
    });

});

describe(@"Observing", ^{

    __block HIBitcoinFormatService *service;

    beforeEach(^{
        service = [HIBitcoinFormatService new];
        service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    });

    context(@"preferred format is being observed", ^{
        service.preferredFormat = @"BTC";
        id mock = [KWMock mock];
        beforeAll(^{
            [[NSNotificationCenter defaultCenter] addObserver:mock
                                                     selector:@selector(receiveNotification:)
                                                         name:HIPreferredFormatChangeNotification
                                                       object:nil];
        });
        afterAll(^{
            [[NSNotificationCenter defaultCenter] removeObserver:mock];
        });

        it(@"should notify the observer the preferred format changes", ^{
            [[[mock should] receive] receiveNotification:nil];
            service.preferredFormat = @"mBTC";
        });
    });
});

SPEC_END
