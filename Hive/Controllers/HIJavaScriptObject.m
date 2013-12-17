//
//  HIJavaScriptObject.m
//  Hive
//
//  Created by Jakub Suder on 06.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIJavaScriptObject.h"

@implementation HIJavaScriptObject


#pragma mark - Property and method name mapping

// override these two in subclasses

+ (NSDictionary *)selectorMap {
    // e.g. @{ @"sendMoneyToAddress:": @"sendMoney" }
    return @{};
}

+ (NSDictionary *)keyMap {
    // e.g. @{ @"minFee": @"MIN_FEE" }
    return @{};
}

+ (NSString *)webScriptNameForSelector:(SEL)sel {
    return [self selectorMap][NSStringFromSelector(sel)];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel {
    return ([self selectorMap][NSStringFromSelector(sel)] == nil);
}

+ (NSString *)webScriptNameForKey:(const char *)name {
    NSString *key = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
    return [self keyMap][key];
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name {
    NSString *key = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
    return ([self keyMap][key] == nil);
}


#pragma mark - JS/Cocoa conversion methods

- (JSValueRef)valueObjectFromDictionary:(NSDictionary *)dictionary {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:NULL];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    JSStringRef jsString = JSStringCreateWithCFString((__bridge CFStringRef) jsonString);
    JSValueRef jsValue = JSValueMakeFromJSONString(self.context, jsString);
    JSStringRelease(jsString);

    return jsValue;
}

- (NSDictionary *)dictionaryFromWebScriptObject:(WebScriptObject *)object {
    if (IsNullOrUndefined(object)) {
        return nil;
    }

    JSPropertyNameArrayRef properties = JSObjectCopyPropertyNames(self.context, [object JSObject]);
    size_t count = JSPropertyNameArrayGetCount(properties);

    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:count];

    for (NSInteger i = 0; i < count; i++) {
        JSStringRef property = JSPropertyNameArrayGetNameAtIndex(properties, i);
        NSString *propertyName = CFBridgingRelease(JSStringCopyCFString(kCFAllocatorDefault, property));

        id value = [object valueForKey:propertyName];

        if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
            dictionary[propertyName] = value;
        } else {
            HILogWarn(@"dictionaryFromWebScriptObject: ignoring value for property %@: %@", propertyName, value);
        }
    }

    JSPropertyNameArrayRelease(properties);

    return dictionary;
}

- (id)webScriptObject:(WebScriptObject *)object valueForProperty:(NSString *)property {
    if ([self webScriptObject:object hasProperty:property]) {
        return [object valueForKey:property];
    } else {
        return nil;
    }
}

- (BOOL)webScriptObject:(WebScriptObject *)object hasProperty:(NSString *)property {
    if (IsNullOrUndefined(object)) {
        return NO;
    }

    JSStringRef jsString = JSStringCreateWithCFString((__bridge CFStringRef) property);
    BOOL hasProperty = JSObjectHasProperty(self.context, [object JSObject], jsString);
    JSStringRelease(jsString);
    
    return hasProperty;
}


#pragma mark - Helpers

- (JSGlobalContextRef)context {
    return self.frame.globalContext;
}

- (void)callCallbackMethod:(WebScriptObject *)callback withArguments:(JSValueRef *)arguments count:(size_t)count {
    if (callback && [callback respondsToSelector:@selector(JSObject)] && [callback JSObject]) {
        JSObjectCallAsFunction(self.context, [callback JSObject], NULL, count, arguments, NULL);
    }
}

@end
