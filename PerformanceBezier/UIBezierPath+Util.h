//
//  UIBezierPath+Util.h
//  ClippingBezier
//
//  Created by Adam Wulf on 5/20/15.
//
//

#import <UIKit/UIKit.h>

@interface UIBezierPath (Util)

+(void) subdivideBezier:(const CGPoint[4])bez intoLeft:(CGPoint[4])bez1 andRight:(CGPoint[4])bez2 atT:(CGFloat)t;

+(void) subdivideBezier:(const CGPoint[4])bez intoLeft:(CGPoint[4])bez1 andRight:(CGPoint[4])bez2 atLength:(CGFloat)length withAcceptableError:(CGFloat)acceptableError withCache:(CGFloat*) subBezierlengthCache;

CGPoint lineSegmentIntersection(CGPoint A, CGPoint B, CGPoint C, CGPoint D);

@end
