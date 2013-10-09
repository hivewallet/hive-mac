//
//  HITitleView.h
//  Hive
//
//  Created by Bazyli Zygan on 02.09.2013.
//  Copyright (c) 2013 Hive Developers. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HITitleView;

@protocol HITitleViewDelegate <NSObject>

- (void)requestedPop:(HITitleView *)titleView;

@end

@interface HITitleView : NSView

@property (nonatomic, assign) id<HITitleViewDelegate> delegate;

- (void)pushTitle:(NSString *)title;
- (void)popToTitleAtPosition:(NSInteger)position;
- (void)updateTitleAtPosition:(NSInteger)position toValue:(NSString *)newTitle;

@end
