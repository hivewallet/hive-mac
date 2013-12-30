//
//  HIJavaScriptObject.h
//  Hive
//
//  Created by Jakub Suder on 06.12.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <WebKit/WebKit.h>

#define SafeJSONValue(x) ((x) ?: [NSNull null])
#define IsNullOrUndefined(x) (!(x) || [(x) isKindOfClass:[WebUndefined class]])
#define ValidateArgument(cl, var) [self validateType:[cl class] ofArgument:var name:@ # var cmd:_cmd]
#define ValidateOptionalArgument(cl, var) [self validateType:[cl class] ofOptionalArgument:var name:@ # var cmd:_cmd]

/*
 Base class for objects whose methods and properties are exposed in the JS API.
 */

@interface HIJavaScriptObject : NSObject

@property (strong) WebFrame *frame;
@property (readonly) JSGlobalContextRef context;

// override these two in subclasses
+ (NSDictionary *)selectorMap;
+ (NSDictionary *)keyMap;

- (JSValueRef)valueObjectFromDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryFromWebScriptObject:(WebScriptObject *)object;
- (id)webScriptObject:(WebScriptObject *)object valueForProperty:(NSString *)property;
- (BOOL)webScriptObject:(WebScriptObject *)object hasProperty:(NSString *)property;

- (void)callCallbackMethod:(WebScriptObject *)callback withArguments:(JSValueRef *)arguments count:(size_t)count;

- (void)validateType:(Class)class ofArgument:(id)argument name:(NSString *)name cmd:(SEL)cmd;
- (void)validateType:(Class)class ofOptionalArgument:(id)argument name:(NSString *)name cmd:(SEL)cmd;

@end
