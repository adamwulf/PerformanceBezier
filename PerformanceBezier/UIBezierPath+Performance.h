//
//  UIBezierPath+Performance.h
//  PerformanceBezier
//
//  Created by Adam Wulf on 1/31/15.
//  Copyright (c) 2015 Milestone Made, LLC. All rights reserved.
//

#import "UIBezierPathProperties.h"
#import <UIKit/UIKit.h>

@interface UIBezierPath (Performance)

// returns the last point of the bezier path.
// if the path ends with a kCGPathElementClosed,
// then the first point of that subpath is returned
- (CGPoint)lastPoint;

// returns the first point of the bezier path
- (CGPoint)firstPoint;

// returns the tangent at the very end of the path
// in radians
- (CGFloat)tangentAtEnd;

// returns YES if the path is closed (or contains at least 1 closed subpath)
// returns NO otherwise
- (BOOL)isClosed;

// returns the total length of the path
- (CGFloat)length;

// returns the tangent of the bezier path at the given t value
- (CGPoint)tangentOnPathAtElement:(NSInteger)elementIndex andTValue:(CGFloat)tVal;

// returns the length of the element within the path
- (CGFloat)lengthOfElement:(NSInteger)elementIndex withAcceptableError:(CGFloat)acceptableError;

// returns the total length of the path up to and including the element at the given index
- (CGFloat)lengthOfPathThroughElement:(NSInteger)elementIndex withAcceptableError:(CGFloat)acceptableError;

// returns the total length of the path up to and including the element at the given index
- (CGFloat)lengthOfPathThroughElement:(NSInteger)elementIndex tValue:(CGFloat)tValue withAcceptableError:(CGFloat)acceptableError;

// for the input bezier curve [start, ctrl1, ctrl2, end]
// return the point at the input T value
+ (CGPoint)pointAtT:(CGFloat)t forBezier:(CGPoint *)bez;

// for the input bezier curve [start, ctrl1, ctrl2, end]
// return the tangent at the input T value
+ (CGPoint)tangentAtT:(CGFloat)t forBezier:(CGPoint *)bez;

+ (void)fillBezier:(CGPoint[4])bezier forNonCloseElement:(CGPathElement)element forNonClosePreviousElement:(CGPathElement)previousElement;

// fill the input point array with [start, ctrl1, ctrl2, end]
// for the element at the given index
- (void)fillBezier:(CGPoint[4])bezier forElement:(NSInteger)elementIndex;

/// for a path that contains multiple subpaths, this will return the range of element indexes
/// for the subpath that contains the input elementIndex
- (NSRange)subpathRangeForElement:(NSInteger)elementIndex;

/// returns if the curve change its position at all between t=0 => t=1 through elementIndex
///
/// for instance, the curve:
/// moveTo(0,0), lineTo(100,0), lineTo(100,0), closePath()
/// would return
/// NO for 0, YES for 1, NO for 2, YES for 3
/// or for instance, the curve:
/// moveTo(0,0), lineTo(100,0), lineTo(0,0), closePath()
/// would return
/// NO for 0, YES for 1, YES for 2, NO for 3
- (BOOL)changesPositionDuringElement:(NSInteger)elementIndex;

@end
