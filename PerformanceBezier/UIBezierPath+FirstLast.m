//
//  UIBezierPath+FirstLast.m
//  iOS-UIBezierPath-Performance
//
//  Created by Adam Wulf on 2/1/15.
//
//

#import "UIBezierPath+FirstLast.h"
#import "UIBezierPath+NSOSX.h"

@implementation UIBezierPath (FirstLast)

-(CGPoint) lastPointCalculated{
    __block BOOL foundFirstYet = NO;
    __block CGPoint firstPoint = CGPointZero;
    __block CGPoint lastPoint = CGPointZero;
    [self iteratePathWithBlock:^(CGPathElement element) {
        CGPoint currPoint = CGPointZero;
        if(element.type == kCGPathElementMoveToPoint){
            currPoint = element.points[0];
            firstPoint = currPoint;
        }else if(element.type == kCGPathElementAddLineToPoint){
            currPoint = element.points[0];
        }else if(element.type == kCGPathElementCloseSubpath){
            currPoint = firstPoint;
        }else if(element.type == kCGPathElementAddCurveToPoint){
            currPoint = element.points[2];
        }else if(element.type == kCGPathElementAddQuadCurveToPoint){
            currPoint = element.points[1];
        }
        if(!foundFirstYet){
            // path should've begun with a moveTo,
            // but this is a sanity check for malformed
            // paths
            firstPoint = currPoint;
            foundFirstYet = YES;
        }
        lastPoint = currPoint;
    }];
    return lastPoint;
}

-(CGPoint) firstPointCalculated{
    __block BOOL foundFirstYet = NO;
    __block CGPoint firstPoint = CGPointZero;
    [self iteratePathWithBlock:^(CGPathElement element) {
        if(!foundFirstYet){
            if(element.type == kCGPathElementMoveToPoint ||
               element.type == kCGPathElementAddLineToPoint){
                firstPoint = element.points[0];
            }else if(element.type == kCGPathElementCloseSubpath){
                firstPoint = firstPoint;
            }else if(element.type == kCGPathElementAddCurveToPoint){
                firstPoint = element.points[2];
            }else if(element.type == kCGPathElementAddQuadCurveToPoint){
                firstPoint = element.points[1];
            }
            foundFirstYet = YES;
        }
    }];
    return firstPoint;
}

@end
