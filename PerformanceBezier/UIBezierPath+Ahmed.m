//
//  UIBezierPath+Ahmed.m
//  PerformanceBezier
//
//  Created by Adam Wulf on 11/18/20.
//  Copyright © 2020 Milestone Made. All rights reserved.
//

#import "UIBezierPath+Ahmed.h"
#import "UIBezierPath+NSOSX.h"
#import "UIBezierPath+Performance.h"
#import "UIBezierPath+Uncached.h"
#import "UIBezierPath+Util.h"
#import "UIBezierPath+NSOSX_Private.h"

static CGFloat kIdealFlatness = 0.01;

@implementation UIBezierPath (Ahmed)

/**
 * call this method on a UIBezierPath to generate
 * a new flattened path
 *
 * This category is named after Athar Luqman Ahmad, who
 * wrote a masters thesis about minimizing the number of
 * lines required to flatten a bezier curve
 *
 * The thesis is available here:
 * http://www.cis.usouthal.edu/~hain/general/Theses/Ahmad_thesis.pdf
 *
 * The algorithm that I use as of 10/09/2012 is a simple
 * recursive algorithm that doesn't use any of ahmed's
 * optimizations yet
 *
 * TODO: add in Ahmed's optimizations
 */
- (UIBezierPath *)bezierPathByFlatteningPath
{
    return [self bezierPathByFlatteningPathWithFlatnessThreshold:kIdealFlatness];
}

- (UIBezierPath *)bezierPathByFlatteningPathAndImmutable:(BOOL)returnCopy
{
    return [self bezierPathByFlatteningPathWithFlatnessThreshold:kIdealFlatness immutable:returnCopy];
}
- (UIBezierPath *)bezierPathByFlatteningPathWithFlatnessThreshold:(CGFloat)flatnessThreshold
{
    return [self bezierPathByFlatteningPathWithFlatnessThreshold:flatnessThreshold immutable:NO];
}

/**
 * @param willBeImmutable YES if this function should return a distinct UIBezier, NO otherwise
 *
 * if the caller plans to modify the returned path, then shouldBeImmutable should
 * be called with NO.
 *
 * if the caller only plans to iterate over and look at the returned value,
 * then shouldBeImmutable should be YES - this is considerably faster to not
 * return a copy if the value will be treated as immutable
 */
- (UIBezierPath *)bezierPathByFlatteningPathWithFlatnessThreshold:(CGFloat)flatnessThreshold immutable:(BOOL)willBeImmutable
{
    UIBezierPathProperties *props = [self pathProperties];
    UIBezierPath *ret = props.bezierPathByFlatteningPath;
    if (ret) {
        if (willBeImmutable)
            return ret;
        return [ret copy];
    }
    if (self.isFlat) {
        if (willBeImmutable)
            return self;
        return [self copy];
    }

    __block NSInteger flattenedElementCount = 0;
    UIBezierPath *newPath = [self newEmptyPath];
    NSInteger elements = [self elementCount];
    NSInteger n;
    CGPoint pointForClose = CGPointMake(0.0, 0.0);
    CGPoint lastPoint = CGPointMake(0.0, 0.0);

    for (n = 0; n < elements; ++n) {
        CGPoint points[3];
        CGPathElement element = [self elementAtIndex:n associatedPoints:points];

        switch (element.type) {
            case kCGPathElementMoveToPoint:
                [newPath moveToPoint:points[0]];
                pointForClose = lastPoint = points[0];
                flattenedElementCount++;
                continue;

            case kCGPathElementAddLineToPoint:
                [newPath addLineToPoint:points[0]];
                lastPoint = points[0];
                flattenedElementCount++;
                break;

            case kCGPathElementAddQuadCurveToPoint:
            case kCGPathElementAddCurveToPoint: {
                //
                // handle both curve types gracefully
                CGPoint curveTo;
                CGPoint ctrl1;
                CGPoint ctrl2;
                if (element.type == kCGPathElementAddQuadCurveToPoint) {
                    CGPoint ctrl = element.points[0];
                    curveTo = element.points[1];
                    ctrl1 = CGPointMake((lastPoint.x + 2.0 * ctrl.x) / 3.0, (lastPoint.y + 2.0 * ctrl.y) / 3.0);
                    ctrl2 = CGPointMake((curveTo.x + 2.0 * ctrl.x) / 3.0, (curveTo.y + 2.0 * ctrl.y) / 3.0);;
                } else { // element.type == kCGPathElementAddCurveToPoint
                    curveTo = element.points[2];
                    ctrl1 = element.points[0];
                    ctrl2 = element.points[1];
                }

                //
                // ok, this is the bezier for our current element
                CGPoint bezier[4] = {lastPoint, ctrl1, ctrl2, curveTo};


                //
                // define our recursive function that will
                // help us split the curve up as needed
                __block __weak void (^weak_flattenCurve)(UIBezierPath *newPath, CGPoint startPoint, CGPoint bez[4]);
                void (^flattenCurve)(UIBezierPath *newPath, CGPoint startPoint, CGPoint bez[4]);
                weak_flattenCurve = flattenCurve = ^(UIBezierPath *newPath, CGPoint startPoint, CGPoint bez[4]) {
                    //
                    // first, calculate the error rate for
                    // a line segement between the start/end points
                    // vs the curve

                    CGPoint onCurve = [[self class] pointAtT:.5 forBezier:bez];

                    CGFloat error1 = [[self class] distanceOfPointToLine:onCurve start:startPoint end:bez[2]];
                    CGFloat error2 = [[self class] distanceOfPointToLine:onCurve start:startPoint end:bez[3]];
                    CGFloat error = MAX(error1, error2);

                    //
                    // if that error is less than our accepted
                    // level of error, then just add a line,
                    //
                    // otherwise, split the curve in half and recur
                    if (error <= flatnessThreshold) {
                        [newPath addLineToPoint:bez[3]];
                        flattenedElementCount++;
                    } else {
                        CGPoint bez1[4], bez2[4];
                        [UIBezierPath subdivideBezierAtT:bez bez1:bez1 bez2:bez2 t:.5];
                        // now we've split the curve in half, and have
                        // two bezier curves bez1 and bez2. recur
                        // on these two halves
                        weak_flattenCurve(newPath, startPoint, bez1);
                        weak_flattenCurve(newPath, startPoint, bez2);
                    }
                };

                flattenCurve(newPath, lastPoint, bezier);

                lastPoint = points[2];
                break;
            }

            case kCGPathElementCloseSubpath:
                [newPath closePath];
                lastPoint = pointForClose;
                flattenedElementCount++;
                break;

            default:
                break;
        }
    }

    // since we just built the flattened path
    // we know how many elements there are, so cache that
    UIBezierPathProperties *newPathProps = [newPath pathProperties];
    newPathProps.cachedElementCount = flattenedElementCount;

    props.bezierPathByFlatteningPath = newPath;

    return [self bezierPathByFlatteningPathAndImmutable:willBeImmutable];
}

@end
