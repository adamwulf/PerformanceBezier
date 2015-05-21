//
//  UIBezierPath+Trim.m
//  DrawKit-iOS
//
//  Created by Adam Wulf on 10/6/12.
//  Copyright (c) 2012 Milestone Made, LLC. All rights reserved.
//

#import "UIBezierPath+Trim.h"
#import <objc/runtime.h>
#import <PerformanceBezier/PerformanceBezier.h>

@implementation UIBezierPath (Trim)

/**
 * this will trim a specific element from a tvalue to a tvalue
 */
-(UIBezierPath*) bezierPathByTrimmingElement:(NSInteger)elementIndex fromTValue:(double)fromTValue toTValue:(double)toTValue{
    __block CGPoint previousEndpoint;
    __block UIBezierPath* outputPath = [UIBezierPath bezierPath];
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger currentIndex){
        if(currentIndex < elementIndex){
            if(element.type == kCGPathElementMoveToPoint){
                // moveto
                previousEndpoint = element.points[0];
            }else if(element.type == kCGPathElementAddCurveToPoint ){
                // curve
                previousEndpoint = element.points[2];
            }else if(element.type == kCGPathElementAddLineToPoint){
                // line
                previousEndpoint = element.points[0];
            }
        }else if(currentIndex == elementIndex){
            if(element.type == kCGPathElementMoveToPoint){
                // moveto
                previousEndpoint = element.points[0];
                [outputPath moveToPoint:element.points[0]];
            }else if(element.type == kCGPathElementAddCurveToPoint ){
                // curve
                CGPoint bez[4];
                bez[0] = previousEndpoint;
                bez[1] = element.points[0];
                bez[2] = element.points[1];
                bez[3] = element.points[2];
                
                previousEndpoint = element.points[2];
                
                CGPoint left[4], right[4];
                subdivideBezierAtT(bez, left, right, toTValue);
                bez[0] = left[0];
                bez[1] = left[1];
                bez[2] = left[2];
                bez[3] = left[3];
                subdivideBezierAtT(bez, left, right, fromTValue / toTValue);
                [outputPath moveToPoint:right[0]];
                [outputPath addCurveToPoint:right[3] controlPoint1:right[1] controlPoint2:right[2]];
            }else if(element.type == kCGPathElementAddLineToPoint){
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
 * this will trim a uibezier path from the input element index
 * and that element's tvalue. it will return all elements after
 * that input
 */
-(UIBezierPath*) bezierPathByTrimmingFromElement:(NSInteger)elementIndex andTValue:(double)tValue{
    __block CGPoint previousEndpoint;
    __block UIBezierPath* outputPath = [UIBezierPath bezierPath];
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger currentIndex){
        if(currentIndex < elementIndex){
            if(element.type == kCGPathElementMoveToPoint){
                // moveto
                previousEndpoint = element.points[0];
            }else if(element.type == kCGPathElementAddCurveToPoint ){
                // curve
                previousEndpoint = element.points[2];
            }else if(element.type == kCGPathElementAddLineToPoint){
                // line
                previousEndpoint = element.points[0];
            }
        }else if(currentIndex == elementIndex){
            if(element.type == kCGPathElementMoveToPoint){
                // moveto
                previousEndpoint = element.points[0];
                [outputPath moveToPoint:element.points[0]];
            }else if(element.type == kCGPathElementAddCurveToPoint ){
                // curve
                CGPoint bez[4];
                bez[0] = previousEndpoint;
                bez[1] = element.points[0];
                bez[2] = element.points[1];
                bez[3] = element.points[2];
                
                previousEndpoint = element.points[2];
                
                CGPoint left[4], right[4];
                subdivideBezierAtT(bez, left, right, tValue);
                [outputPath moveToPoint:right[0]];
                [outputPath addCurveToPoint:right[3] controlPoint1:right[1] controlPoint2:right[2]];
            }else if(element.type == kCGPathElementAddLineToPoint){
                // line
                CGPoint startPoint = CGPointMake(previousEndpoint.x + tValue * (element.points[0].x - previousEndpoint.x),
                                                 previousEndpoint.y + tValue * (element.points[0].y - previousEndpoint.y));
                previousEndpoint = element.points[0];
                [outputPath moveToPoint:startPoint];
                [outputPath addLineToPoint:element.points[0]];
            }
        }else if(currentIndex > elementIndex){
            if(element.type == kCGPathElementMoveToPoint){
                // moveto
                previousEndpoint = element.points[0];
                [outputPath moveToPoint:element.points[0]];
            }else if(element.type == kCGPathElementAddCurveToPoint ){
                // curve
                previousEndpoint = element.points[2];
                [outputPath addCurveToPoint:element.points[2] controlPoint1:element.points[0] controlPoint2:element.points[1]];
            }else if(element.type == kCGPathElementAddLineToPoint){
                // line
                previousEndpoint = element.points[0];
                [outputPath addLineToPoint:element.points[0]];
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
-(UIBezierPath*) bezierPathByTrimmingToElement:(NSInteger)elementIndex andTValue:(double)tValue{
    __block CGPoint previousEndpoint;
    __block UIBezierPath* outputPath = [UIBezierPath bezierPath];
    [self iteratePathWithBlock:^(CGPathElement element, NSUInteger currentIndex){
        if(currentIndex == elementIndex){
            if(element.type == kCGPathElementMoveToPoint){
                // moveto
                previousEndpoint = element.points[0];
                [outputPath moveToPoint:element.points[0]];
            }else if(element.type == kCGPathElementAddCurveToPoint ){
                // curve
                CGPoint bez[4];
                bez[0] = previousEndpoint;
                bez[1] = element.points[0];
                bez[2] = element.points[1];
                bez[3] = element.points[2];
                
                previousEndpoint = element.points[2];
                
                CGPoint left[4], right[4];
                subdivideBezierAtT(bez, left, right, tValue);
                [outputPath addCurveToPoint:left[3] controlPoint1:left[1] controlPoint2:left[2]];
            }else if(element.type == kCGPathElementAddLineToPoint){
                // line
                CGPoint endPoint = CGPointMake(previousEndpoint.x + tValue * (element.points[0].x - previousEndpoint.x),
                                               previousEndpoint.y + tValue * (element.points[0].y - previousEndpoint.y));
                previousEndpoint = element.points[0];
                [outputPath addLineToPoint:endPoint];
            }
        }else if(currentIndex < elementIndex){
            if(element.type == kCGPathElementMoveToPoint){
                // moveto
                previousEndpoint = element.points[0];
                [outputPath moveToPoint:element.points[0]];
            }else if(element.type == kCGPathElementAddCurveToPoint ){
                // curve
                previousEndpoint = element.points[2];
                [outputPath addCurveToPoint:element.points[2] controlPoint1:element.points[0] controlPoint2:element.points[1]];
            }else if(element.type == kCGPathElementAddLineToPoint){
                // line
                previousEndpoint = element.points[0];
                [outputPath addLineToPoint:element.points[0]];
            }
        }
    }];
    
    return outputPath;
}

+(CGFloat) lengthOfBezier:(const CGPoint[4])bez withAccuracy:(CGFloat)accuracy{
    return lengthOfBezier(bez, accuracy);
}


#pragma mark - Subdivide helpers by Alastair J. Houghton

// Subdivide a Bézier (50% subdivision)
inline static void subdivideBezier(const CGPoint bez[4], CGPoint bez1[4], CGPoint bez2[4])
{
    CGPoint q;
    
    bez1[0].x = bez[0].x;
    bez1[0].y = bez[0].y;
    bez2[3].x = bez[3].x;
    bez2[3].y = bez[3].y;
    
    q.x = (bez[1].x + bez[2].x) / 2.0;
    q.y = (bez[1].y + bez[2].y) / 2.0;
    bez1[1].x = (bez[0].x + bez[1].x) / 2.0;
    bez1[1].y = (bez[0].y + bez[1].y) / 2.0;
    bez2[2].x = (bez[2].x + bez[3].x) / 2.0;
    bez2[2].y = (bez[2].y + bez[3].y) / 2.0;
    
    bez1[2].x = (bez1[1].x + q.x) / 2.0;
    bez1[2].y = (bez1[1].y + q.y) / 2.0;
    bez2[1].x = (q.x + bez2[2].x) / 2.0;
    bez2[1].y = (q.y + bez2[2].y) / 2.0;
    
    bez1[3].x = bez2[0].x = (bez1[2].x + bez2[1].x) / 2.0;
    bez1[3].y = bez2[0].y = (bez1[2].y + bez2[1].y) / 2.0;
}

// Subdivide a Bézier (specific division)
void subdivideBezierAtT(const CGPoint bez[4], CGPoint bez1[4], CGPoint bez2[4], CGFloat t)
{
    CGPoint q;
    CGFloat mt = 1 - t;
    
    bez1[0].x = bez[0].x;
    bez1[0].y = bez[0].y;
    bez2[3].x = bez[3].x;
    bez2[3].y = bez[3].y;
    
    q.x = mt * bez[1].x + t * bez[2].x;
    q.y = mt * bez[1].y + t * bez[2].y;
    bez1[1].x = mt * bez[0].x + t * bez[1].x;
    bez1[1].y = mt * bez[0].y + t * bez[1].y;
    bez2[2].x = mt * bez[2].x + t * bez[3].x;
    bez2[2].y = mt * bez[2].y + t * bez[3].y;
    
    bez1[2].x = mt * bez1[1].x + t * q.x;
    bez1[2].y = mt * bez1[1].y + t * q.y;
    bez2[1].x = mt * q.x + t * bez2[2].x;
    bez2[1].y = mt * q.y + t * bez2[2].y;
    
    bez1[3].x = bez2[0].x = mt * bez1[2].x + t * bez2[1].x;
    bez1[3].y = bez2[0].y = mt * bez1[2].y + t * bez2[1].y;
}


// Distance between two points
inline CGFloat distanceBetween(CGPoint a, CGPoint b)
{
    return hypotf( a.x - b.x, a.y - b.y );
}

// Length of a curve
CGFloat lengthOfBezier(const  CGPoint bez[4], CGFloat acceptableError)
{
    CGFloat   polyLen = 0.0;
    CGFloat   chordLen = distanceBetween (bez[0], bez[3]);
    CGFloat   retLen, errLen;
    NSUInteger n;
    
    for (n = 0; n < 3; ++n)
        polyLen += distanceBetween (bez[n], bez[n + 1]);
    
    errLen = polyLen - chordLen;
    
    if (errLen > acceptableError) {
        CGPoint left[4], right[4];
        subdivideBezier (bez, left, right);
        retLen = (lengthOfBezier (left, acceptableError)
                  + lengthOfBezier (right, acceptableError));
    } else {
        retLen = 0.5 * (polyLen + chordLen);
    }
    
    return retLen;
}

// Split a Bézier curve at a specific length
CGFloat subdivideBezierAtLength (const CGPoint bez[4],
                                        CGPoint bez1[4],
                                        CGPoint bez2[4],
                                        CGFloat length,
                                        CGFloat acceptableError)
{
    return subdivideBezierAtLengthWithCache(bez, bez1, bez2, length, acceptableError, NULL);
}

/**
 * will split the input bezier curve at the input length
 * within a given margin of error
 *
 * the two curves will exactly match the original curve
 */
CGFloat subdivideBezierAtLengthWithCache(const CGPoint bez[4],
                                        CGPoint bez1[4],
                                        CGPoint bez2[4],
                                        CGFloat length,
                                        CGFloat acceptableError,
                                        CGFloat* subBezierlengthCache){
    CGFloat top = 1.0, bottom = 0.0;
    CGFloat t, prevT;
    
    prevT = t = 0.5;
    for (;;) {
        CGFloat len1;
        
        subdivideBezierAtT (bez, bez1, bez2, t);
        
        int lengthCacheIndex = (int)floorf(t*1000);
        len1 = subBezierlengthCache[lengthCacheIndex];
        if(!len1){
            len1 = [UIBezierPath lengthOfBezier:bez1 withAccuracy:0.5 * acceptableError];
            subBezierlengthCache[lengthCacheIndex] = len1;
        }
        
        if (fabs (length - len1) < acceptableError){
            return len1;
        }
        
        if (length > len1) {
            bottom = t;
            t = 0.5 * (t + top);
        } else if (length < len1) {
            top = t;
            t = 0.5 * (bottom + t);
        }
        
        if (t == prevT){
            subBezierlengthCache[lengthCacheIndex] = len1;
            return len1;
        }
        
        prevT = t;
    }
}


@end
