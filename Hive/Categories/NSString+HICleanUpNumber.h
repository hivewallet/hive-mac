/* Clean up extra characters in numbers for parsing.
 */
@interface NSString(HICleanUpNumber)

/* Returns the decimal number in the string with all extra characters removed.

 This removes currency information, thousands separators and spaces,
 making it suited for use with NSDecimalNumber's initWithString:locale:.
 */
- (NSString *)hi_stringWithCleanedUpDecimalNumberUsingLocale:(NSLocale *)locale;

@end
