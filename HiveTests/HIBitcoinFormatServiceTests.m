#import "HIBitcoinFormatService.h"

@interface HIBitcoinFormatServiceTests : XCTestCase

@property (nonatomic, strong, readonly) HIBitcoinFormatService *service;

@end

@implementation HIBitcoinFormatServiceTests

- (void)setUp {
    [super setUp];

    _service = [HIBitcoinFormatService new];
    _service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
}

#pragma mark - formatting

- (void)testPreferredFormatString {
    self.service.preferredFormat = @"mBTC";

    NSString *string = [self.service stringForBitcoin:160000];

    assertThat(string, equalTo(@"1.6"));
}

- (void)testPreferredFormatStringWithDesignator {
    self.service.preferredFormat = @"µBTC";

    NSString *string = [self.service stringWithDesignatorForBitcoin:160];

    assertThat(string, equalTo(@"1.6 µBTC"));
}

- (void)testFormatBtcString {
    NSString *format = @"BTC";

    NSString *string = [self.service stringForBitcoin:60000000 withFormat:format];

    assertThat(string, equalTo(@"0.60"));
}

- (void)testFormatBtcStringWithManyDecimalPlaces {
    NSString *format = @"BTC";

    NSString *string = [self.service stringForBitcoin:123456789 withFormat:format];

    assertThat(string, equalTo(@"1.23456789"));
}

- (void)testFormatMBtcString {
    NSString *format = @"mBTC";

    NSString *string = [self.service stringForBitcoin:160000 withFormat:format];

    assertThat(string, equalTo(@"1.6"));
}

- (void)testFormatUBtcString {
    NSString *format = @"µBTC";

    NSString *string = [self.service stringForBitcoin:160 withFormat:format];

    assertThat(string, equalTo(@"1.6"));
}

- (void)testFormatUSatoshiString {
    NSString *format = @"satoshi";

    NSString *string = [self.service stringForBitcoin:60 withFormat:format];

    assertThat(string, equalTo(@"60"));
}

- (void)testFormatStringWithComma {
    _service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
    NSString *format = @"BTC";

    NSString *string = [self.service stringForBitcoin:60000000 withFormat:format];

    assertThat(string, equalTo(@"0,60"));
}

#pragma mark - parsing

- (void)testParseBtcString {
    NSString *format = @"BTC";

    satoshi_t amount = [self.service parseString:@"0.6"
                                      withFormat:format
                                           error:NULL];

    assertThat(@(amount), equalToUnsignedLongLong(60000000));
}

- (void)testParseMBtcString {
    NSString *format = @"mBTC";

    satoshi_t amount = [self.service parseString:@"0.6"
                                      withFormat:format
                                           error:NULL];

    assertThat(@(amount), equalToUnsignedLongLong(60000));
}

- (void)testParseUBtcString {
    NSString *format = @"µBTC";

    satoshi_t amount = [self.service parseString:@"0.6"
                                      withFormat:format
                                           error:NULL];

    assertThat(@(amount), equalToUnsignedLongLong(60));
}

- (void)testParseUSatoshiString {
    NSString *format = @"satoshi";

    satoshi_t amount = [self.service parseString:@"60"
                                      withFormat:format
                                           error:NULL];

    assertThat(@(amount), equalToUnsignedLongLong(60));
}

- (void)testParseStringWithComma {
    _service.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
    NSString *format = @"BTC";

    satoshi_t amount = [self.service parseString:@"0,6"
                                      withFormat:format
                                           error:NULL];

    assertThat(@(amount), equalToUnsignedLongLong(60000000));
}

- (void)testParsingIllegalStringWithError {
    NSString *format = @"BTC";
    NSError *error;

    satoshi_t amount = [self.service parseString:@"xx"
                                      withFormat:format
                                           error:&error];

    assertThat(@(amount), equalToUnsignedLongLong(0));
    assertThat(error, notNilValue());
}

- (void)testParsingIllegalStringWithNullError {
    NSString *format = @"BTC";

    satoshi_t amount = [self.service parseString:@"xx"
                                      withFormat:format
                                           error:NULL];

    assertThat(@(amount), equalToUnsignedLongLong(0));
}

@end
