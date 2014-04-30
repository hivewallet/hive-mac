#import "HICurrencyFormatService.h"

SPEC_BEGIN(HICurrencyFormatServiceSpec)

describe(@"Formatting", ^{

    __block HICurrencyFormatService *service;

    beforeEach(^{
        service = [HICurrencyFormatService new];
        service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    });

    it(@"has user locale", ^{
        assertThat([HICurrencyFormatService new].locale, is([NSLocale currentLocale]));
    });

    it(@"formats value", ^{
        NSString *string = [service stringForValue:@1060.5 inCurrency:@"USD"];
        assertThat(string, equalTo(@"1,060.50"));
    });

    it(@"rounds the value", ^{
        NSString *string = [service stringForValue:@1.503 inCurrency:@"USD"];
        assertThat(string, equalTo(@"1.50"));
    });

    it(@"formats negative values", ^{
        NSString *string = [service stringWithUnitForValue:@-1060.5 inCurrency:@"USD"];
        assertThat(string, equalTo(@"-1,060.50"));
    });

    context(@"using a different locale", ^{
        it(@"formats value", ^{
            service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
            NSString *string = [service stringForValue:@1060.5 inCurrency:@"USD"];
            assertThat(string, equalTo(@"1.060,50"));
        });
    });

    context(@"formatting a currency with three decimal places", ^{
        it(@"formats value", ^{
            NSString *string = [service stringForValue:@1060.5 inCurrency:@"TND"];
            assertThat(string, equalTo(@"1,060.500"));
        });
    });

    context(@"formatting with unit", ^{
        it(@"prepend unit", ^{
            NSString *string = [service stringWithUnitForValue:@1060.5 inCurrency:@"USD"];
            assertThat(string, equalTo(@"$1,060.50"));
        });
        it(@"appends unit for some locales", ^{
            service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
            NSString *string = [service stringWithUnitForValue:@1060.5 inCurrency:@"EUR"];
            assertThat(string, equalTo(@"1.060,50\u00A0€"));
        });
        it(@"prepends unit if it doesn't match locale's currency", ^{
            NSString *string = [service stringWithUnitForValue:@1060.5 inCurrency:@"PLN"];
            assertThat(string, equalTo(@"zł1,060.50"));
        });
    });

});

describe(@"Parsing", ^{

    __block HICurrencyFormatService *service;

    beforeEach(^{
        service = [HICurrencyFormatService new];
        service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    });

    it(@"should parse value correctly", ^{
        NSNumber *amount = [service parseString:@"1,000.6" error:NULL];
        assertThat(amount, equalTo(@1000.6));
    });

    it(@"should parse value without leading zero correctly", ^{
        NSNumber *amount = [service parseString:@".60" error:NULL];
        assertThat(amount, equalTo(@.6));
    });

    context(@"parsing with unit", ^{
        it(@"should parse value with unit", ^{
            NSNumber *amount = [service parseString:@"$1,000.6" error:NULL];
            assertThat(amount, equalTo(@1000.6));
        });
        it(@"should parse value with trailing unit", ^{
            service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
            NSNumber *amount = [service parseString:@"1.000,6\u00A0€" error:NULL];
            assertThat(amount, equalTo(@1000.6));
        });
        it(@"should parse value with currency if it doesn't matches the locale's currency", ^{
            NSNumber *amount = [service parseString:@"zł1,000.60" error:NULL];
            assertThat(amount, equalTo(@1000.6));
        });
    });

    context(@"using a different locale", ^{
        it(@"should parse value correctly", ^{
            service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
            NSNumber *amount = [service parseString:@"1.000,6" error:NULL];
            assertThat(amount, equalTo(@1000.6));
        });
        it(@"should parse value with spaces correctly", ^{
            service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"sv_SE"];
            NSNumber *amount = [service parseString:@"1 000,6" error:NULL];
            assertThat(amount, equalTo(@1000.6));
        });
    });

    context(@"parsing illegal string", ^{
        context(@"error variable is set", ^{
            it(@"should return nil", ^{
                NSError *error;
                NSNumber *amount = [service parseString:@"xx" error:&error];
                assertThat(amount, nilValue());
            });
            it(@"should set error", ^{
                NSError *error;
                [service parseString:@"xx" error:&error];
                assertThat(error, notNilValue());
            });
        });
        context(@"error variable is NULL", ^{
            it(@"should return 0", ^{
                NSNumber *amount = [service parseString:@"xx" error:NULL];
                assertThat(amount, nilValue());
            });
        });
    });
});

SPEC_END
