#import "HICurrencyFormatService.h"

@interface HICurrencyFormatServiceTests : XCTestCase

@property (nonatomic, strong, readonly) HICurrencyFormatService *service;

@property (nonatomic, copy) NSNotification *receivedNotification;

@end

@implementation HICurrencyFormatServiceTests

- (void)setUp {
    [super setUp];

    _service = [HICurrencyFormatService new];
    _service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
}

- (void)testShouldStartWithUserLocale {
    assertThat([HICurrencyFormatService new].locale, is([NSLocale currentLocale]));
}

#pragma mark - formatting

- (void)testFormatValue {
    NSString *string = [self.service stringForValue:@1060.5 inCurrency:@"USD"];

    assertThat(string, equalTo(@"1,060.50"));
}

- (void)testFormatValueUsingDifferentLocale {
    self.service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];

    NSString *string = [self.service stringForValue:@1060.5 inCurrency:@"USD"];

    assertThat(string, equalTo(@"1.060,50"));
}

- (void)testFormatValueForStringWithThreeDecimalPlaces {
    NSString *string = [self.service stringForValue:@1060.5 inCurrency:@"TND"];

    assertThat(string, equalTo(@"1,060.500"));
}

- (void)testRoundDecimalPlaces {
    NSString *string = [self.service stringForValue:@1.503 inCurrency:@"USD"];

    assertThat(string, equalTo(@"1.50"));
}

- (void)testFormatValueWithUnit {
    NSString *string = [self.service stringWithUnitForValue:@1060.5 inCurrency:@"USD"];

    assertThat(string, equalTo(@"$1,060.50"));
}

- (void)testFormatValueWithTrailingUnit {
    self.service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];

    NSString *string = [self.service stringWithUnitForValue:@1060.5 inCurrency:@"EUR"];

    assertThat(string, equalTo(@"1.060,50\u00A0€"));
}

- (void)testFormatValueWithUnitThatDoesntMatchLocale {
    NSString *string = [self.service stringWithUnitForValue:@1060.5 inCurrency:@"PLN"];

    assertThat(string, equalTo(@"zł1,060.50"));
}

#pragma mark - parsing

- (void)testParseString {
    NSNumber *amount = [self.service parseString:@"1,000.6" error:NULL];

    assertThat(amount, equalTo(@1000.6));
}

- (void)testParseStringDifferentLocale {
    self.service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];

    NSNumber *amount = [self.service parseString:@"1.000,6" error:NULL];

    assertThat(amount, equalTo(@1000.6));
}

- (void)testParseStringUsingSpaceAsThousandsSeparator {
    self.service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"sv_SE"];

    NSNumber *amount = [self.service parseString:@"1 000,6" error:NULL];

    assertThat(amount, equalTo(@1000.6));
}

- (void)testParsingIllegalStringWithError {
    NSError *error;

    NSNumber *amount = [self.service parseString:@"xx" error:&error];

    assertThat(amount, nilValue());
    assertThat(error, notNilValue());
}

- (void)testParsingIllegalStringWithNullError {
    NSNumber *amount = [self.service parseString:@"xx" error:NULL];

    assertThat(amount, nilValue());
}

- (void)testParseStringWithUnit {
    NSNumber *amount = [self.service parseString:@"$1,000.6" error:NULL];

    assertThat(amount, equalTo(@1000.6));
}

- (void)testParseStringWithTrailingUnit {
    self.service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];

    NSNumber *amount = [self.service parseString:@"1.000,6\u00A0€" error:NULL];

    assertThat(amount, equalTo(@1000.6));
}

- (void)testParseStringWithUnitNotMatchingLocale {
    NSNumber *amount = [self.service parseString:@"zł1,000.60" error:NULL];

    assertThat(amount, equalTo(@1000.6));
}

@end
