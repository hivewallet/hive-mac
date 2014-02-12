#import "NSWindow+HIShake.h"

#import <QuartzCore/QuartzCore.h>

@implementation NSWindow (HIShake)

- (void)hiShake {
    [self setAnimations:@{
        @"frameOrigin": [self createShakeAnimation],
    }];
    self.animator.frameOrigin = self.frame.origin;
}

- (CAKeyframeAnimation *)createShakeAnimation {
    CAKeyframeAnimation *shakeAnimation = [CAKeyframeAnimation animation];
    shakeAnimation.duration = .5;

    CGPathRef animationPath = [self createAnimationPath];
    shakeAnimation.path = animationPath;

    return shakeAnimation;
}

- (CGPathRef)createAnimationPath {
    CGPoint origin = self.frame.origin;
    CGMutablePathRef animationPath = CGPathCreateMutable();
    CGPathMoveToPoint(animationPath, NULL, origin.x, origin.y);
    int shakes = 3;
    for (int index = 0; index < shakes; index++) {
        float offset = 10.0 * (shakes - index) / shakes;
        CGPathAddLineToPoint(animationPath, NULL, origin.x - offset, origin.y);
        CGPathAddLineToPoint(animationPath, NULL, origin.x + offset, origin.y);
    }
    CGPathCloseSubpath(animationPath);

    return (__bridge CGPathRef) CFBridgingRelease(animationPath);
}

@end
