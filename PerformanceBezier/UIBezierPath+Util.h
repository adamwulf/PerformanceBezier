//
//  UIBezierPath+Util.h
//  PerformanceBezier
//
//  Created by Adam Wulf on 5/20/15.
//
//

#import <UIKit/UIKit.h>

@interface UIBezierPath (Util)

+(CGFloat) lengthOfBezier:(const CGPoint[4])bez withAccuracy:(CGFloat)accuracy;

+(void)subdivideBezierAtT:(const CGPoint[4])bez bez1:(CGPoint[4])bez1 bez2:(CGPoint[4])bez2 t:(CGFloat)t;

+(CGFloat)distanceOfPointToLine:(CGPoint)point start:(CGPoint)start end:(CGPoint)end;

+(CGFloat)distance:(const CGPoint)p1 p2:(const CGPoint) p2;

+(CGPoint)bezierTangentAtT:(const CGPoint[4])bez t:(CGFloat)t;

+(CGFloat)subdivideBezier:(const CGPoint [4])bez bez1:(CGPoint[4])bez1 bez2:(CGPoint[4])bez2 atLength:(CGFloat)length acceptableError:(CGFloat)acceptableError;

+(CGFloat)subdivideBezier:(const CGPoint [4])bez bez1:(CGPoint[4])bez1 bez2:(CGPoint[4])bez2 atLength:(CGFloat)length acceptableError:(CGFloat)acceptableError withCache:(CGFloat*) subBezierLengthCache;

+(CGPoint)lineSegmentIntersectionPointA:(CGPoint)A pointB:(CGPoint)B pointC:(CGPoint)C pointD:(CGPoint)D;

@end
