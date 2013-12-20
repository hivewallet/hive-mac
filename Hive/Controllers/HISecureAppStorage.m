//
//  HISecureAppStorage.m
//  Hive
//
//  Created by Jakub Suder on 20.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import "HIApplication.h"
#import "HISecureAppStorage.h"

@interface HISecureAppStorage () {
    HIApplication *_application;
    NSMutableDictionary *_items;
}

@end


@implementation HISecureAppStorage

#pragma mark - Method & property mapping

+ (NSDictionary *)selectorMap {
    static NSDictionary *selectorMap;

    if (!selectorMap) {
        selectorMap = @{
                        @"setItemForKey:value:callback:": @"setItem",
                        @"getItemForKey:callback:": @"getItem",
                        @"removeItemForKey:callback:": @"removeItem",
                        @"clearStorageWithCallback:": @"clear",
                      };
    }

    return selectorMap;
}


#pragma mark - init & cleanup

- (id)initWithApplication:(HIApplication *)application frame:(WebFrame *)frame {
    self = [super init];

    if (self) {
        _application = application;
        _items = [NSMutableDictionary dictionary];
        self.frame = frame;
    }

    return self;
}


#pragma mark - JS API methods

// TODO: fake in-memory implementation, replace with a real one

- (void)setItemForKey:(NSString *)key value:(id)value callback:(WebScriptObject *)callback {
    if (![key isKindOfClass:[NSString class]]) {
        [WebScriptObject throwException:@"key must be a string"];
        return;
    }

    if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
        _items[key] = value;
    } else if (IsNullOrUndefined(value)) {
        [_items removeObjectForKey:key];
    } else {
        [WebScriptObject throwException:@"value must be a string or number"];
        return;
    }

    if (!IsNullOrUndefined(callback)) {
        JSValueRef error = JSValueMakeNull(self.context);
        [self callCallbackMethod:callback withArguments:&error count:1];
    }
}

- (void)getItemForKey:(NSString *)key callback:(WebScriptObject *)callback {
    if (IsNullOrUndefined(callback)) {
        [WebScriptObject throwException:@"callback argument is undefined"];
        return;
    }

    JSValueRef result;

    if ([_items[key] isKindOfClass:[NSString class]]) {
        JSStringRef jString = JSStringCreateWithCFString((__bridge CFStringRef) _items[key]);
        result = JSValueMakeString(self.context, jString);
        JSStringRelease(jString);
    } else if ([_items[key] isKindOfClass:[NSNumber class]]) {
        result = JSValueMakeNumber(self.context, [_items[key] doubleValue]);
    } else {
        result = JSValueMakeNull(self.context);
    }

    [self callCallbackMethod:callback withArguments:&result count:1];
}

- (void)removeItemForKey:(NSString *)key callback:(WebScriptObject *)callback {
    [_items removeObjectForKey:key];

    if (!IsNullOrUndefined(callback)) {
        JSValueRef error = JSValueMakeNull(self.context);
        [self callCallbackMethod:callback withArguments:&error count:1];
    }
}

- (void)clearStorageWithCallback:(WebScriptObject *)callback {
    [_items removeAllObjects];

    if (!IsNullOrUndefined(callback)) {
        JSValueRef error = JSValueMakeNull(self.context);
        [self callCallbackMethod:callback withArguments:&error count:1];
    }
}

@end
