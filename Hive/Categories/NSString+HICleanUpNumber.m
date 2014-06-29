#import "NSString+HICleanUpNumber.h"

@implementation NSString(HICleanUpNumber)

- (NSString *)hi_stringWithCleanedUpDecimalNumberUsingLocale:(NSLocale *)locale {

    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.locale = locale;

    NSMutableCharacterSet *allowedCharacters = [NSMutableCharacterSet new];
    [allowedCharacters formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
    [allowedCharacters formUnionWithCharacterSet:
        [NSCharacterSet characterSetWithCharactersInString:formatter.decimalSeparator]];
    [allowedCharacters formUnionWithCharacterSet:
        [NSCharacterSet characterSetWithCharactersInString:@"-"]];

    NSCharacterSet *forbiddenCharacters = [allowedCharacters invertedSet];

    NSMutableString *string = [self mutableCopy];
    NSRange range = [string rangeOfCharacterFromSet:forbiddenCharacters];
    while (range.location != NSNotFound) {
        [string deleteCharactersInRange:range];
        range = [string rangeOfCharacterFromSet:forbiddenCharacters];
    }

    BOOL isNumber = string.length > 0;
    return isNumber ? string : nil;
}

@end
