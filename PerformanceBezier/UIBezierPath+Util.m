//
//  UIBezierPath+Util.m
//  ClippingBezier
//
//  Created by Adam Wulf on 5/20/15.
//
//

#import "PerformanceBezier.h"
#import "UIBezierPath+Util.h"
#import "UIBezierPath+Trim.h"
#import "UIBezierPath+Performance.h"

@implementation UIBezierPath (Util)

+(void) subdivideBezier:(const CGPoint[4])bez intoLeft:(CGPoint[4])bez1 andRight:(CGPoint[4])bez2 atT:(CGFloat)t{
    subdivideBezierAtT(bez, bez1, bez2, t);
}

+(void) subdivideBezier:(const CGPoint[4])bez intoLeft:(CGPoint[4])bez1 andRight:(CGPoint[4])bez2{
    subdivideBezierAtT(bez, bez1, bez2, .5);
}

+(void) subdivideBezier:(const CGPoint[4])bez intoLeft:(CGPoint[4])bez1 andRight:(CGPoint[4])bez2 atLength:(CGFloat)length withAcceptableError:(CGFloat)acceptableError withCache:(CGFloat*) subBezierlengthCache{
    subdivideBezierAtLengthWithCache(bez, bez1, bez2, length, acceptableError,subBezierlengthCache);
}

//  public domain function by Darel Rex Finley, 2006



//  Determines the intersection point of the line segment defined by points A and B
//  with the line segment defined by points C and D.
//
//  Returns YES if the intersection point was found, and stores that point in X,Y.
//  Returns NO if there is no determinable intersection point, in which case X,Y will
//  be unmodified.

CGPoint lineSegmentIntersection(CGPoint A, CGPoint B, CGPoint C, CGPoint D) {
    
    double  distAB, theCos, theSin, newX, ABpos ;
    
    //  Fail if either line segment is zero-length.
    if ((A.x==B.x && A.y==B.y) || (C.x==D.x && C.y==D.y)) return CGPointNotFound;
    
    //  Fail if the segments share an end-point.
    if ((A.x==C.x && A.y==C.y) ||
        (B.x==C.x && B.y==C.y) ||
        (A.x==D.x && A.y==D.y) ||
        (B.x==D.x && B.y==D.y)) {
        return CGPointNotFound;
    }
    
    //  (1) Translate the system so that point A is on the origin.
    B.x-=A.x; B.y-=A.y;
    C.x-=A.x; C.y-=A.y;
    D.x-=A.x; D.y-=A.y;
    
    //  Discover the length of segment A-B.
    distAB=sqrt(B.x*B.x+B.y*B.y);
    
    //  (2) Rotate the system so that point B is on the positive X axis.
    theCos=B.x/distAB;
    theSin=B.y/distAB;
    newX=C.x*theCos+C.y*theSin;
    C.y  =C.y*theCos-C.x*theSin;
    C.x=newX;
    newX=D.x*theCos+D.y*theSin;
    D.y  =D.y*theCos-D.x*theSin;
    D.x=newX;
    
    //  Fail if segment C-D doesn't cross line A-B.
    if ((C.y<0. && D.y<0.) || (C.y>=0. && D.y>=0.)) return CGPointNotFound;
    
    //  (3) Discover the position of the intersection point along line A-B.
    ABpos=D.x+(C.x-D.x)*D.y/(D.y-C.y);
    
    //  Fail if segment C-D crosses line A-B outside of segment A-B.
    if (ABpos<0. || ABpos>distAB) return CGPointNotFound;
    
    //  (4) Apply the discovered position to line A-B in the original coordinate system.
    //  Success.
    return CGPointMake(A.x+ABpos*theCos, A.y+ABpos*theSin);
}

@end
