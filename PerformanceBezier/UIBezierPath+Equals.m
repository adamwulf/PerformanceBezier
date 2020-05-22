//
//  UIBezierPath+Debug.m
//  LooseLeaf
//
//  Created by Adam Wulf on 6/3/14.
//  Copyright (c) 2014 Milestone Made, LLC. All rights reserved.
//

#import "UIBezierPath+Equals.h"
#import "PerformanceBezier.h"

@implementation UIBezierPath (Equals)

// CGPathEqualToPath returned NO for two paths that return YES for the logic below.
// so i'm swapping out in favor of the explicit path element checking
- (BOOL)isEqualToBezierPath:(UIBezierPath *)path
{
    if ([self elementCount] != [path elementCount]) {
        return false;
    }

    for (NSInteger i = 0; i < [self elementCount]; i++) {
        CGPoint myPoints[3];
        CGPoint otherPoints[3];
        CGPathElement myEle = [self elementAtIndex:i associatedPoints:myPoints];
        CGPathElement otherEle = [path elementAtIndex:i associatedPoints:otherPoints];

        if (myEle.type != otherEle.type) {
            return false;
        }

        if (!CGPointEqualToPoint(myPoints[0], otherPoints[0]) && myEle.type != kCGPathElementCloseSubpath) {
            return false;
        }

        if (!CGPointEqualToPoint(myPoints[1], otherPoints[1]) && (myEle.type == kCGPathElementAddQuadCurveToPoint || myEle.type == kCGPathElementAddCurveToPoint)) {
            return false;
        }

        if (!CGPointEqualToPoint(myPoints[2], otherPoints[2]) && myEle.type == kCGPathElementAddCurveToPoint) {
            return false;
        }
    }

    return true;
}

- (BOOL)isEqualToBezierPath:(UIBezierPath *)path withAccuracy:(CGFloat)accuracy
{
    if ([self elementCount] != [path elementCount]) {
        return false;
    }

    for (NSInteger i = 0; i < [self elementCount]; i++) {
        CGPoint myPoints[3];
        CGPoint otherPoints[3];
        CGPathElement myEle = [self elementAtIndex:i associatedPoints:myPoints];
        CGPathElement otherEle = [path elementAtIndex:i associatedPoints:otherPoints];

        if (myEle.type != otherEle.type) {
            return false;
        }
        
        CGFloat(^dist)(CGPoint, CGPoint) = ^(CGPoint p1, CGPoint p2){
            CGFloat xDiff = p2.x - p1.x;
            CGFloat yDiff = p2.y - p1.y;
            return (CGFloat) sqrt(xDiff * xDiff + yDiff * yDiff);
        };

        if (myEle.type != kCGPathElementCloseSubpath && dist(myPoints[0], otherPoints[0]) > accuracy) {
            return false;
        }

        if ((myEle.type == kCGPathElementAddQuadCurveToPoint || myEle.type == kCGPathElementAddCurveToPoint) && dist(myPoints[1], otherPoints[1]) > accuracy) {
            return false;
        }

        if (myEle.type == kCGPathElementAddCurveToPoint && dist(myPoints[2], otherPoints[2]) > accuracy) {
            return false;
        }
    }

    return true;
}

@end
