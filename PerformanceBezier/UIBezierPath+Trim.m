//
//  UIBezierPath+Trim.m
//  PerformanceBezier
//
//  Created by Adam Wulf on 10/6/12.
//  Copyright (c) 2012 Milestone Made, LLC. All rights reserved.
//

#import "UIBezierPath+Trim.h"
#import <PerformanceBezier/PerformanceBezier.h>
#import <objc/runtime.h>

@implementation UIBezierPath (Trim)

/**
 * this will trim a specific element from a tvalue to a tvalue
 */
- (UIBezierPath *)bezierPathByTrimmingElement:(NSInteger)elementIndex fromTValue:(double)fromTValue toTValue:(double)toTValue
{
    __block CGPoint previousEndpoint;
    __block UIBezierPath *outputPath = [self newEmptyPath];
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger currentIndex) {
      if (currentIndex < elementIndex) {
          if (element.type == kCGPathElementMoveToPoint) {
              // moveto
              previousEndpoint = element.points[0];
          } else if (element.type == kCGPathElementAddCurveToPoint) {
              // curve
              previousEndpoint = element.points[2];
          } else if (element.type == kCGPathElementAddLineToPoint) {
              // line
              previousEndpoint = element.points[0];
          }
      } else if (currentIndex == elementIndex) {
          if (element.type == kCGPathElementMoveToPoint) {
              // moveto
              previousEndpoint = element.points[0];
              [outputPath moveToPoint:element.points[0]];
          } else if (element.type == kCGPathElementAddCurveToPoint) {
              // curve
              CGPoint bez[4];
              bez[0] = previousEndpoint;
              bez[1] = element.points[0];
              bez[2] = element.points[1];
              bez[3] = element.points[2];

              previousEndpoint = element.points[2];

              CGPoint left[4], right[4];
              [UIBezierPath subdivideBezierAtT:bez bez1:left bez2:right t:toTValue];
              bez[0] = left[0];
              bez[1] = left[1];
              bez[2] = left[2];
              bez[3] = left[3];
              [UIBezierPath subdivideBezierAtT:bez bez1:left bez2:right t:fromTValue / toTValue];
              [outputPath moveToPoint:right[0]];
              [outputPath addCurveToPoint:right[3] controlPoint1:right[1] controlPoint2:right[2]];
          } else if (element.type == kCGPathElementAddLineToPoint) {
              // line
              CGPoint startPoint = CGPointMake(previousEndpoint.x + fromTValue * (element.points[0].x - previousEndpoint.x),
                                               previousEndpoint.y + fromTValue * (element.points[0].y - previousEndpoint.y));
              CGPoint endPoint = CGPointMake(previousEndpoint.x + toTValue * (element.points[0].x - previousEndpoint.x),
                                             previousEndpoint.y + toTValue * (element.points[0].y - previousEndpoint.y));
              previousEndpoint = element.points[0];
              [outputPath moveToPoint:startPoint];
              [outputPath addLineToPoint:endPoint];
          }
      }
    }];

    return outputPath;
}

/**
 * Trim the bezier path from T=0 of the input element. If necessary, a moveTo element will be prepended
 * to the output path so that the returned path starts at the same place that the element does in this path.
 * `[bezierPathByTrimmingFromElement:1]` effectively creates a copy of the existing path
 */
-(UIBezierPath*) bezierPathByTrimmingFromElement:(NSInteger)elementIndex {
    if(elementIndex == 0){
        return [self copy];
    }

    __block CGPoint lastMoveTo = [self firstPoint];
    __block CGPoint lastPoint = [self firstPoint];
    UIBezierPath *retPath = [self newEmptyPath];
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger idx) {
        if (idx == elementIndex && element.type != kCGPathElementMoveToPoint){
            [retPath moveToPoint:lastPoint];
        }
        if (idx >= elementIndex){
            switch (element.type) {
                case kCGPathElementMoveToPoint:
                    [retPath moveToPoint:element.points[0]];
                    break;
                case kCGPathElementAddCurveToPoint:
                    [retPath addCurveToPoint:element.points[2] controlPoint1:element.points[0] controlPoint2:element.points[1]];
                    break;
                case kCGPathElementAddQuadCurveToPoint:
                    [retPath addQuadCurveToPoint:element.points[1] controlPoint:element.points[0]];
                    break;
                case kCGPathElementAddLineToPoint:
                    [retPath addLineToPoint:element.points[0]];
                    break;
                case kCGPathElementCloseSubpath:
                    [retPath closePath];
                    break;
            }
        }
        switch (element.type) {
            case kCGPathElementMoveToPoint:
                lastMoveTo = element.points[0];
                lastPoint = element.points[0];
                break;
            case kCGPathElementAddCurveToPoint:
                lastPoint = element.points[2];
                break;
            case kCGPathElementAddQuadCurveToPoint:
                lastPoint = element.points[1];
                break;
            case kCGPathElementAddLineToPoint:
                lastPoint = element.points[0];
                break;
            case kCGPathElementCloseSubpath:
                lastPoint = lastMoveTo;
                break;
        }
    }];

    return retPath;
}


/**
 * this will trim a uibezier path from the input element index
 * and that element's tvalue. it will return all elements after
 * that input
 */
- (UIBezierPath *)bezierPathByTrimmingFromElement:(NSInteger)elementIndex andTValue:(double)tValue
{
    __block CGPoint previousMoveTo = [self firstPoint];
    __block CGPoint previousEndpoint;
    __block UIBezierPath *outputPath = [self newEmptyPath];
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger currentIndex) {
        if (element.type == kCGPathElementMoveToPoint) {
            previousMoveTo = element.points[0];
        }
      if (currentIndex < elementIndex) {
          if (element.type == kCGPathElementMoveToPoint) {
              previousEndpoint = element.points[0];
          } else if (element.type == kCGPathElementAddCurveToPoint) {
              previousEndpoint = element.points[2];
          } else if (element.type == kCGPathElementAddQuadCurveToPoint) {
              previousEndpoint = element.points[1];
          } else if (element.type == kCGPathElementAddLineToPoint) {
              previousEndpoint = element.points[0];
          } else if (element.type == kCGPathElementCloseSubpath) {
              previousEndpoint = previousMoveTo;
          }
      } else if (currentIndex == elementIndex) {
          if (element.type == kCGPathElementMoveToPoint) {
              // moveto
              previousEndpoint = element.points[0];
              [outputPath moveToPoint:element.points[0]];
          } else if (element.type == kCGPathElementAddCurveToPoint) {
              // curve
              CGPoint bez[4];
              bez[0] = previousEndpoint;
              bez[1] = element.points[0];
              bez[2] = element.points[1];
              bez[3] = element.points[2];

              previousEndpoint = element.points[2];

              CGPoint left[4], right[4];
              [UIBezierPath subdivideBezierAtT:bez bez1:left bez2:right t:tValue];
              [outputPath moveToPoint:right[0]];
              [outputPath addCurveToPoint:right[3] controlPoint1:right[1] controlPoint2:right[2]];
          } else if (element.type == kCGPathElementAddQuadCurveToPoint) {
              // curve
              CGPoint lastPoint = previousEndpoint;
              CGPoint ctrlOrig = element.points[0];
              CGPoint curveTo = element.points[1];
              CGPoint ctrl1 = CGPointMake((lastPoint.x + 2.0 * ctrlOrig.x) / 3.0, (lastPoint.y + 2.0 * ctrlOrig.y) / 3.0);
              CGPoint ctrl2 = CGPointMake((curveTo.x + 2.0 * ctrlOrig.x) / 3.0, (curveTo.y + 2.0 * ctrlOrig.y) / 3.0);;

              CGPoint bez[4];
              bez[0] = previousEndpoint;
              bez[1] = ctrl1;
              bez[2] = ctrl2;
              bez[3] = curveTo;

              previousEndpoint = element.points[1];

              CGPoint left[4], right[4];
              [UIBezierPath subdivideBezierAtT:bez bez1:left bez2:right t:tValue];
              [outputPath moveToPoint:right[0]];
              [outputPath addCurveToPoint:right[3] controlPoint1:right[1] controlPoint2:right[2]];
          } else if (element.type == kCGPathElementAddLineToPoint) {
              // line
              CGPoint startPoint = CGPointMake(previousEndpoint.x + tValue * (element.points[0].x - previousEndpoint.x),
                                               previousEndpoint.y + tValue * (element.points[0].y - previousEndpoint.y));
              previousEndpoint = element.points[0];
              [outputPath moveToPoint:startPoint];
              [outputPath addLineToPoint:element.points[0]];
          } else if (element.type == kCGPathElementCloseSubpath) {
              // line
              CGPoint startPoint = CGPointMake(previousEndpoint.x + tValue * (previousMoveTo.x - previousEndpoint.x),
                                               previousEndpoint.y + tValue * (previousMoveTo.y - previousEndpoint.y));
              previousEndpoint = previousMoveTo;
              [outputPath moveToPoint:startPoint];
              [outputPath addLineToPoint:previousMoveTo];
          }
      } else if (currentIndex > elementIndex) {
          if (element.type == kCGPathElementMoveToPoint) {
              // moveto
              previousEndpoint = element.points[0];
              [outputPath moveToPoint:element.points[0]];
          } else if (element.type == kCGPathElementAddCurveToPoint) {
              // curve
              previousEndpoint = element.points[2];
              [outputPath addCurveToPoint:element.points[2] controlPoint1:element.points[0] controlPoint2:element.points[1]];
          } else if (element.type == kCGPathElementAddQuadCurveToPoint) {
              // curve
              previousEndpoint = element.points[1];
              [outputPath addQuadCurveToPoint:element.points[1] controlPoint:element.points[0]];
          } else if (element.type == kCGPathElementAddLineToPoint) {
              // line
              previousEndpoint = element.points[0];
              [outputPath addLineToPoint:element.points[0]];
          } else if (element.type == kCGPathElementCloseSubpath) {
              // don't add a zero-length line element
              if (!CGPointEqualToPoint(previousMoveTo, previousEndpoint)) {
                  [outputPath addLineToPoint:previousMoveTo];
              }
          }
      }
    }];

    return outputPath;
}

/**
 * this will trim a uibezier path to the input element index
 * and that element's tvalue. it will return all elements before
 * that input
 */
- (UIBezierPath *)bezierPathByTrimmingToElement:(NSInteger)elementIndex andTValue:(double)tValue
{
    __block CGPoint previousMoveTo = [self firstPoint];
    __block CGPoint previousEndpoint;
    __block UIBezierPath *outputPath = [self newEmptyPath];
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger currentIndex) {
      if (currentIndex == elementIndex) {
          if (element.type == kCGPathElementMoveToPoint) {
              // moveto
              previousEndpoint = element.points[0];
              [outputPath moveToPoint:element.points[0]];
          } else if (element.type == kCGPathElementAddCurveToPoint) {
              // curve
              CGPoint bez[4];
              bez[0] = previousEndpoint;
              bez[1] = element.points[0];
              bez[2] = element.points[1];
              bez[3] = element.points[2];

              previousEndpoint = element.points[2];

              CGPoint left[4], right[4];
              [UIBezierPath subdivideBezierAtT:bez bez1:left bez2:right t:tValue];
              [outputPath addCurveToPoint:left[3] controlPoint1:left[1] controlPoint2:left[2]];
          } else if (element.type == kCGPathElementAddQuadCurveToPoint) {
              // curve
              CGPoint lastPoint = previousEndpoint;
              CGPoint ctrlOrig = element.points[0];
              CGPoint curveTo = element.points[1];
              CGPoint ctrl1 = CGPointMake((lastPoint.x + 2.0 * ctrlOrig.x) / 3.0, (lastPoint.y + 2.0 * ctrlOrig.y) / 3.0);
              CGPoint ctrl2 = CGPointMake((curveTo.x + 2.0 * ctrlOrig.x) / 3.0, (curveTo.y + 2.0 * ctrlOrig.y) / 3.0);;

              CGPoint bez[4];
              bez[0] = previousEndpoint;
              bez[1] = ctrl1;
              bez[2] = ctrl2;
              bez[3] = curveTo;

              previousEndpoint = element.points[1];

              CGPoint left[4], right[4];
              [UIBezierPath subdivideBezierAtT:bez bez1:left bez2:right t:tValue];
              [outputPath addCurveToPoint:left[3] controlPoint1:left[1] controlPoint2:left[2]];
          } else if (element.type == kCGPathElementAddLineToPoint) {
              // line
              CGPoint endPoint = CGPointMake(previousEndpoint.x + tValue * (element.points[0].x - previousEndpoint.x),
                                             previousEndpoint.y + tValue * (element.points[0].y - previousEndpoint.y));
              previousEndpoint = element.points[0];
              [outputPath addLineToPoint:endPoint];
          } else if (element.type == kCGPathElementCloseSubpath) {
              // line
              CGPoint endPoint = CGPointMake(previousEndpoint.x + tValue * (previousMoveTo.x - previousEndpoint.x),
                                             previousEndpoint.y + tValue * (previousMoveTo.y - previousEndpoint.y));
              previousEndpoint = previousMoveTo;
              [outputPath addLineToPoint:endPoint];
          }
      } else if (currentIndex < elementIndex) {
          if (element.type == kCGPathElementMoveToPoint) {
              // moveto
              previousEndpoint = element.points[0];
              previousMoveTo = previousEndpoint;
              [outputPath moveToPoint:element.points[0]];
          } else if (element.type == kCGPathElementAddCurveToPoint) {
              // curve
              previousEndpoint = element.points[2];
              [outputPath addCurveToPoint:element.points[2] controlPoint1:element.points[0] controlPoint2:element.points[1]];
          } else if (element.type == kCGPathElementAddQuadCurveToPoint) {
              // curve
              previousEndpoint = element.points[1];
              [outputPath addQuadCurveToPoint:element.points[1] controlPoint:element.points[0]];
          } else if (element.type == kCGPathElementAddLineToPoint) {
              // line
              previousEndpoint = element.points[0];
              [outputPath addLineToPoint:element.points[0]];
          } else if (element.type == kCGPathElementCloseSubpath) {
              // line
              previousEndpoint = previousMoveTo;
              [outputPath closePath];
          }
      }
    }];

    return outputPath;
}

+ (void)subdivideBezier:(const CGPoint[4])bez intoLeft:(CGPoint[4])bez1 andRight:(CGPoint[4])bez2 atT:(CGFloat)t
{
    [UIBezierPath subdivideBezierAtT:bez bez1:bez1 bez2:bez2 t:t];
}

+ (void)subdivideBezier:(const CGPoint[4])bez intoLeft:(CGPoint[4])bez1 andRight:(CGPoint[4])bez2
{
    [UIBezierPath subdivideBezierAtT:bez bez1:bez1 bez2:bez2 t:.5];
}

+ (void)subdivideBezier:(const CGPoint[4])bez intoLeft:(CGPoint[4])bez1 andRight:(CGPoint[4])bez2 atLength:(CGFloat)length withAcceptableError:(CGFloat)acceptableError withCache:(CGFloat *)subBezierlengthCache
{
    [self subdivideBezier:bez bez1:bez1 bez2:bez2 atLength:length acceptableError:acceptableError withCache:subBezierlengthCache];
}

@end
