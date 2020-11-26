//
//  UIBezierPath+Performance.m
//  PerformanceBezier
//
//  Created by Adam Wulf on 1/31/15.
//  Copyright (c) 2015 Milestone Made, LLC. All rights reserved.
//

#import "UIBezierPath+Performance.h"
#import "JRSwizzle.h"
#import "PerformanceBezier.h"
#import "UIBezierPath+FirstLast.h"
#import "UIBezierPath+NSOSX.h"
#import "UIBezierPath+Uncached.h"
#import "UIBezierPath+Util.h"
#import <objc/runtime.h>

static char BEZIER_PROPERTIES;

@implementation UIBezierPath (Performance)

- (UIBezierPathProperties *)pathProperties
{
    UIBezierPathProperties *props = objc_getAssociatedObject(self, &BEZIER_PROPERTIES);
    if (!props) {
        props = [[[UIBezierPathProperties alloc] init] autorelease];
        objc_setAssociatedObject(self, &BEZIER_PROPERTIES, props, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return props;
}

- (void)setTangentAtEnd:(CGFloat)tangent
{
    [self pathProperties].tangentAtEnd = tangent;
}

- (CGPoint)lastPoint
{
    UIBezierPathProperties *props = [self pathProperties];
    if (!props.hasLastPoint) {
        props.hasLastPoint = YES;
        props.lastPoint = [self lastPointCalculated];
#ifdef MMPreventBezierPerformance
    } else {
        [self simulateNoBezierCaching];
#endif
    }
    return props.lastPoint;
}
- (CGPoint)firstPoint
{
    UIBezierPathProperties *props = [self pathProperties];
    if (!props.hasFirstPoint) {
        props.hasFirstPoint = YES;
        props.firstPoint = [self firstPointCalculated];
#ifdef MMPreventBezierPerformance
    } else {
        [self simulateNoBezierCaching];
#endif
    }
    return props.firstPoint;
}
- (BOOL)isClosed
{
    UIBezierPathProperties *props = [self pathProperties];
    if (!props.knowsIfClosed) {
        // we dont know if the path is closed, so
        // find a close element if we have one
        [self iteratePathWithBlock:^(CGPathElement ele, NSUInteger idx) {
          if (ele.type == kCGPathElementCloseSubpath) {
              props.isClosed = YES;
          }
        }];
        props.knowsIfClosed = YES;
#ifdef MMPreventBezierPerformance
    } else {
        [self simulateNoBezierCaching];
#endif
    }
    return props.isClosed;
}

- (CGFloat)length
{
    if ([self elementCount] > 0) {
        return [self lengthOfPathThroughElement:[self elementCount] - 1 withAcceptableError:0.5];
    } else {
        return 0;
    }
}

- (CGFloat)tangentAtEnd
{
#ifdef MMPreventBezierPerformance
    [self simulateNoBezierCaching];
#endif
    return [self pathProperties].tangentAtEnd;
}

/**
 * this is a property on the category, as described in:
 * https://github.com/techpaa/iProperties
 */
- (void)setBezierPathByFlatteningPath:(UIBezierPath *)bezierPathByFlatteningPath
{
    [self pathProperties].bezierPathByFlatteningPath = bezierPathByFlatteningPath;
}


/**
 * this is a property on the category, as described in:
 * https://github.com/techpaa/iProperties
 *
 *
 * this is for internal PerformanceBezier use only
 *
 * Since iOS doesn't allow a quick lookup for element count,
 * this property will act as a cache for the element count after
 * it has been calculated once
 */
- (void)setCachedElementCount:(NSInteger)_cachedElementCount
{
    [self pathProperties].cachedElementCount = _cachedElementCount;
}

- (NSInteger)cachedElementCount
{
    return [self pathProperties].cachedElementCount;
}


+ (void)fillBezier:(CGPoint[4])bezier forNonCloseElement:(CGPathElement)element forNonClosePreviousElement:(CGPathElement)previousElement
{
    if (previousElement.type == kCGPathElementMoveToPoint ||
        previousElement.type == kCGPathElementAddLineToPoint) {
        bezier[0] = previousElement.points[0];
    } else if (previousElement.type == kCGPathElementAddQuadCurveToPoint) {
        bezier[0] = previousElement.points[1];
    } else if (previousElement.type == kCGPathElementAddCurveToPoint) {
        bezier[0] = previousElement.points[2];
    }

    if (element.type == kCGPathElementMoveToPoint) {
        bezier[0] = element.points[0];
        bezier[1] = element.points[0];
        bezier[2] = element.points[0];
        bezier[3] = element.points[0];
        return;
    }

    if (previousElement.type == kCGPathElementCloseSubpath) {
        @throw [NSException exceptionWithName:@"BezierElementException" reason:@"Cannot fill bezier for close element" userInfo:nil];
    }

    if (element.type == kCGPathElementAddLineToPoint) {
        bezier[1] = CGPointMake((2.0 * bezier[0].x + element.points[0].x) / 3.0,
                                (2.0 * bezier[0].y + element.points[0].y) / 3.0);
        ;
        bezier[2] = CGPointMake((bezier[0].x + 2.0 * element.points[0].x) / 3.0,
                                (bezier[0].y + 2.0 * element.points[0].y) / 3.0);
        ;
        bezier[3] = element.points[0];
    } else if (element.type == kCGPathElementAddQuadCurveToPoint) {
        CGPoint lastPoint = bezier[0];
        CGPoint ctrlOrig = element.points[0];
        CGPoint curveTo = element.points[1];
        CGPoint ctrl1 = CGPointMake((lastPoint.x + 2.0 * ctrlOrig.x) / 3.0, (lastPoint.y + 2.0 * ctrlOrig.y) / 3.0);
        CGPoint ctrl2 = CGPointMake((curveTo.x + 2.0 * ctrlOrig.x) / 3.0, (curveTo.y + 2.0 * ctrlOrig.y) / 3.0);
        ;

        bezier[1] = ctrl1;
        bezier[2] = ctrl2;
        bezier[3] = element.points[1];
    } else if (element.type == kCGPathElementAddCurveToPoint) {
        bezier[1] = element.points[0];
        bezier[2] = element.points[1];
        bezier[3] = element.points[2];
    }
}

- (void)fillBezier:(CGPoint[4])bezier forElement:(NSInteger)elementIndex
{
    if (elementIndex >= [self elementCount] || elementIndex < 0) {
        @throw [NSException exceptionWithName:@"BezierElementException" reason:@"Element index is out of range" userInfo:nil];
    }
    if (elementIndex == 0) {
        bezier[0] = self.firstPoint;
        bezier[1] = self.firstPoint;
        bezier[2] = self.firstPoint;
        bezier[3] = self.firstPoint;
        return;
    }

    CGPathElement previousElement = [self elementAtIndex:elementIndex - 1];
    CGPathElement element = [self elementAtIndex:elementIndex];

    if (previousElement.type == kCGPathElementMoveToPoint ||
        previousElement.type == kCGPathElementAddLineToPoint) {
        bezier[0] = previousElement.points[0];
    } else if (previousElement.type == kCGPathElementAddQuadCurveToPoint) {
        bezier[0] = previousElement.points[1];
    } else if (previousElement.type == kCGPathElementAddCurveToPoint) {
        bezier[0] = previousElement.points[2];
    }

    if (element.type == kCGPathElementCloseSubpath) {
        // the distance of a closeSubpath element is from the last point on the subpath
        // and the intial moveTo element of that subpath. If we can't find a moveTo,
        // then this is a malformed path and we'll return a single point bezier for this element
        NSInteger moveToIndex = elementIndex;
        CGPathElement previousMoveTo = previousElement;
        while (previousMoveTo.type != kCGPathElementMoveToPoint && moveToIndex > 0) {
            moveToIndex -= 1;
            previousMoveTo = [self elementAtIndex:moveToIndex];
        }
        bezier[1] = bezier[0];
        if (previousMoveTo.type == kCGPathElementMoveToPoint) {
            bezier[3] = previousMoveTo.points[0];
        } else {
            // path definition error, we weren't able to find a moveTo element
            bezier[3] = bezier[0];
        }

        bezier[1] = CGPointMake((2.0 * bezier[0].x + bezier[3].x) / 3.0,
                                (2.0 * bezier[0].y + bezier[3].y) / 3.0);
        ;
        bezier[2] = CGPointMake((bezier[0].x + 2.0 * bezier[3].x) / 3.0,
                                (bezier[0].y + 2.0 * bezier[3].y) / 3.0);
        ;

    } else {
        [UIBezierPath fillBezier:bezier forNonCloseElement:element forNonClosePreviousElement:previousElement];
    }
}

- (CGPoint)tangentOnPathAtElement:(NSInteger)elementIndex andTValue:(CGFloat)tVal
{
    if (elementIndex >= [self elementCount] || elementIndex < 0) {
        @throw [NSException exceptionWithName:@"BezierElementException" reason:@"Element index is out of range" userInfo:nil];
    }
    if (elementIndex == 0) {
        // instead of calculating the tangent of the moveTo,
        // we'll calculate the tangent at the very start
        // of the element after the moveTo
        elementIndex += 1;
        tVal = 0;
    } else if ([self elementAtIndex:elementIndex].type == kCGPathElementCloseSubpath) {
        CGPoint points[3];
        CGPathElement ele = [self elementAtIndex:elementIndex - 1 associatedPoints:points];
        CGPoint elePoint = points[[UIBezierPath numberOfPointsForElement:ele] - 1];
        CGPoint firstPoint = [self firstPoint];
        if (elementIndex > 1 && CGPointEqualToPoint(firstPoint, elePoint)) {
            // it's a close path that won't create a line to the start of the path, we're already here.
            // so instead get the tangent at the end of the previous element
            return [self tangentOnPathAtElement:elementIndex - 1 andTValue:1.0];
        } else {
            CGPoint tan = CGPointMake(firstPoint.x - elePoint.x, firstPoint.y - elePoint.y);
            CGFloat mag = sqrt(tan.x * tan.x + tan.y * tan.y);
            return CGPointMake(tan.x / mag, tan.y / mag);
        }
    }

    CGPoint bezier[4];

    [self fillBezier:bezier forElement:elementIndex];
    CGPoint tan = [UIBezierPath tangentAtT:tVal forBezier:bezier];
    CGFloat mag = sqrt(tan.x * tan.x + tan.y * tan.y);

    // noramlize
    tan.x = tan.x / mag;
    tan.y = tan.y / mag;

    return tan;
}

- (CGFloat)lengthOfElement:(NSInteger)elementIndex withAcceptableError:(CGFloat)acceptableError
{
    if (elementIndex >= [self elementCount] || elementIndex < 0) {
        @throw [NSException exceptionWithName:@"BezierElementException" reason:@"Element index is out of range" userInfo:nil];
    }
    if (elementIndex == 0) {
        return 0;
    }

    UIBezierPathProperties *props = [self pathProperties];

    CGFloat cached = [props cachedLengthForElementIndex:elementIndex acceptableError:acceptableError];

    if (cached != -1) {
        return cached;
    }

    CGPoint bezier[4];

    [self fillBezier:bezier forElement:elementIndex];

    CGFloat len = [UIBezierPath lengthOfBezier:bezier withAccuracy:acceptableError];

    [props cacheLength:len forElementIndex:elementIndex acceptableError:acceptableError];

    if (elementIndex > 0) {
        // build up the cache for the total length of the path up to a given element index as we go
        CGFloat totalLengthOfPathBefore = [self lengthOfPathThroughElement:elementIndex - 1 withAcceptableError:acceptableError];
        if (totalLengthOfPathBefore != -1) {
            [props cacheLengthOfPath:totalLengthOfPathBefore + len throughElementIndex:elementIndex acceptableError:acceptableError];
        }
    }

    return len;
}

- (CGFloat)lengthOfPathThroughElement:(NSInteger)elementIndex withAcceptableError:(CGFloat)acceptableError
{
    return [self lengthOfPathThroughElement:elementIndex tValue:1 withAcceptableError:acceptableError];
}

/// Returns the length of the path from the start of the path up to and including this element through t = 1.
// returns the total length of the path up to and including the element at the given index
- (CGFloat)lengthOfPathThroughElement:(NSInteger)elementIndex tValue:(CGFloat)tValue withAcceptableError:(CGFloat)acceptableError;
{
    if (elementIndex >= [self elementCount] || elementIndex < 0) {
        @throw [NSException exceptionWithName:@"BezierElementException" reason:@"Element index is out of range" userInfo:nil];
    }
    if (elementIndex == 0) {
        return 0;
    }

    UIBezierPathProperties *props = [self pathProperties];

    // find the first element that we need to cache for its length
    // we'll immediately decrement in the loop below, so we need to add one here so that we start
    // in the right place
    NSInteger firstToCache = elementIndex;
    CGFloat cached = -1;
    do {
        firstToCache -= 1;
        cached = [props cachedLengthOfPathThroughElementIndex:firstToCache acceptableError:acceptableError];
    } while (cached == -1 && firstToCache > 0);

    // we eitehr have a cached value with a > 0 index, or our index is 0
    CGFloat lengthSoFar = (firstToCache == 0) ? 0 : [props cachedLengthOfPathThroughElementIndex:firstToCache acceptableError:acceptableError];

    // for all the items after our cache hit up through the element we need
    // we should calculate, cache, and add to our total length
    for (NSInteger indexToCache = firstToCache + 1; indexToCache <= elementIndex; indexToCache++) {
        CGPoint bezier[4];
        CGPathElement ele = [self elementAtIndex:indexToCache];

        // skip calculating distance between the previous element and the start of a new subpath
        if (ele.type != kCGPathElementMoveToPoint) {
            if (tValue == 1) {
                cached = [props cachedLengthOfPathThroughElementIndex:indexToCache acceptableError:acceptableError];

                if (cached >= 0) {
                    lengthSoFar = cached;
                    continue;
                }

                CGFloat len = [self lengthOfElement:indexToCache withAcceptableError:acceptableError];

                lengthSoFar += len;

                [props cacheLengthOfPath:lengthSoFar throughElementIndex:indexToCache acceptableError:acceptableError];

                continue;
            }

            if (indexToCache == elementIndex && tValue == 0) {
                // the length to t == 0 is just zero. Adding the line below for explicitness
                lengthSoFar += 0;
            } else if (indexToCache == elementIndex && tValue < 1) {
                [self fillBezier:bezier forElement:indexToCache];
                CGPoint left[4];
                CGPoint right[4];
                [UIBezierPath subdivideBezier:bezier intoLeft:left andRight:right atT:tValue];
                CGFloat len = [UIBezierPath lengthOfBezier:left withAccuracy:acceptableError];

                lengthSoFar += len;
            } else {
                CGFloat len = [self lengthOfElement:indexToCache withAcceptableError:acceptableError];

                // build up the cache for the total length of the path up to a given element index as we go
                lengthSoFar += len;
            }
        }

        if (indexToCache != elementIndex || tValue == 1) {
            [props cacheLengthOfPath:lengthSoFar throughElementIndex:indexToCache acceptableError:acceptableError];
        }
    }

    return lengthSoFar;
}

/**
* calculate the point on a bezier at time t
* where 0 < t < 1
*/
+ (CGPoint)pointAtT:(CGFloat)t forBezier:(CGPoint[4])bez
{
    CGPoint q;
    CGFloat mt = 1 - t;

    CGPoint bez1[4];
    CGPoint bez2[4];

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

    return CGPointMake(bez1[3].x, bez1[3].y);
}

+ (CGPoint)tangentAtT:(CGFloat)t forBezier:(CGPoint *)bez
{
    return [[self class] bezierTangentAtT:bez t:t];
}


#pragma mark - Swizzle

///////////////////////////////////////////////////////////////////////////
//
// All of these methods are to listen to UIBezierPath method calls
// so that we can add new functionality on top of them without
// changing any of the default behavior.
//
// These methods help maintain:
// 1. the cached flat version of this path
// 2. the flag for if this path is already flat or not


- (void)ahmed_swizzle_dealloc
{
    objc_setAssociatedObject(self, &BEZIER_PROPERTIES, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self ahmed_swizzle_dealloc];
}

- (id)swizzle_initWithCoder:(NSCoder *)decoder
{
    self = [self swizzle_initWithCoder:decoder];
    UIBezierPathProperties *props = [decoder decodeObjectForKey:@"pathProperties"];
    objc_setAssociatedObject(self, &BEZIER_PROPERTIES, props, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    NSDictionary<NSString *, NSObject<NSCoding> *> *userInfo = [decoder decodeObjectOfClass:[NSMutableDictionary class] forKey:@"userInfo"];

    if (userInfo) {
        [[self userInfo] addEntriesFromDictionary:userInfo];
    }

    return self;
}

+ (id)swizzle_bezierPathWithCGPath:(CGPathRef)cgPath
{
    UIBezierPath *path = [UIBezierPath swizzle_bezierPathWithCGPath:cgPath];
    __block BOOL endsWithMoveTo = false;
    __block BOOL isFlat = true;
    [path iteratePathWithBlock:^(CGPathElement element, NSUInteger idx) {
      endsWithMoveTo = element.type == kCGPathElementMoveToPoint;
      isFlat = isFlat && element.type != kCGPathElementAddCurveToPoint && element.type != kCGPathElementAddQuadCurveToPoint;
    }];
    path.pathProperties.lastAddedElementWasMoveTo = endsWithMoveTo;
    path.pathProperties.isFlat = isFlat;
    return path;
}

- (void)swizzle_encodeWithCoder:(NSCoder *)aCoder
{
    [self swizzle_encodeWithCoder:aCoder];
    [aCoder encodeObject:self.pathProperties forKey:@"pathProperties"];
    [aCoder encodeObject:self.userInfo forKey:@"userInfo"];
}
- (void)ahmed_swizzle_applyTransform:(CGAffineTransform)transform
{
    // reset our path properties
    BOOL isClosed = [self pathProperties].isClosed;
    BOOL knowsIfClosed = [self pathProperties].knowsIfClosed;
    UIBezierPathProperties *props = [[[UIBezierPathProperties alloc] init] autorelease];
    props.isClosed = isClosed;
    props.knowsIfClosed = knowsIfClosed;
    objc_setAssociatedObject(self, &BEZIER_PROPERTIES, props, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self ahmed_swizzle_applyTransform:transform];
}

- (void)swizzle_moveToPoint:(CGPoint)point
{
    UIBezierPathProperties *props = [self pathProperties];
    [props resetSubpathRangeCount];
    props.bezierPathByFlatteningPath = nil;
    BOOL isEmpty = [self isEmpty];
    if (isEmpty || props.isFlat) {
        props.isFlat = YES;
    }
    if (isEmpty) {
        props.hasFirstPoint = YES;
        props.firstPoint = point;
        props.cachedElementCount = 1;
    } else if (props.cachedElementCount) {
        if (!props.lastAddedElementWasMoveTo) {
            // when adding multiple moveTo elements to a path
            // in a row, iOS actually just modifies the last moveTo
            // instead of having tons of useless moveTos
            props.cachedElementCount = props.cachedElementCount + 1;
        } else if (props.cachedElementCount == 1) {
            // otherwise, the first and only point was
            // a move to, so update our first point
            props.firstPoint = point;
        }
    }
    props.hasLastPoint = YES;
    props.lastPoint = point;
    props.tangentAtEnd = 0;
    props.lastAddedElementWasMoveTo = YES;
    [self swizzle_moveToPoint:point];
}
- (void)swizzle_addLineToPoint:(CGPoint)point
{
    UIBezierPathProperties *props = [self pathProperties];
    [props resetSubpathRangeCount];
    props.lastAddedElementWasMoveTo = NO;
    props.bezierPathByFlatteningPath = nil;
    if ([self isEmpty] || props.isFlat) {
        props.isFlat = YES;
    }
    if (props.cachedElementCount) {
        props.cachedElementCount = props.cachedElementCount + 1;
    }
    props.tangentAtEnd = [self calculateTangentBetween:point andPoint:props.lastPoint];
    props.hasLastPoint = YES;
    props.lastPoint = point;
    [self swizzle_addLineToPoint:point];
}
- (void)swizzle_addCurveToPoint:(CGPoint)point controlPoint1:(CGPoint)ctrl1 controlPoint2:(CGPoint)ctrl2
{
    UIBezierPathProperties *props = [self pathProperties];
    [props resetSubpathRangeCount];
    props.lastAddedElementWasMoveTo = NO;
    props.bezierPathByFlatteningPath = nil;
    if ([self isEmpty] || props.isFlat) {
        props.isFlat = NO;
    }
    if (props.cachedElementCount) {
        props.cachedElementCount = props.cachedElementCount + 1;
    }
    props.tangentAtEnd = [self calculateTangentBetween:point andPoint:ctrl2];
    props.hasLastPoint = YES;
    props.lastPoint = point;
    [self swizzle_addCurveToPoint:point controlPoint1:ctrl1 controlPoint2:ctrl2];
}
- (void)swizzle_quadCurveToPoint:(CGPoint)point controlPoint:(CGPoint)ctrl1
{
    UIBezierPathProperties *props = [self pathProperties];
    [props resetSubpathRangeCount];
    props.lastAddedElementWasMoveTo = NO;
    props.bezierPathByFlatteningPath = nil;
    if ([self isEmpty] || props.isFlat) {
        props.isFlat = NO;
    }
    if (props.cachedElementCount) {
        props.cachedElementCount = props.cachedElementCount + 1;
    }
    props.hasLastPoint = YES;
    props.lastPoint = point;
    props.tangentAtEnd = [self calculateTangentBetween:point andPoint:ctrl1];
    [self swizzle_quadCurveToPoint:point controlPoint:ctrl1];
}
- (void)swizzle_closePath
{
    if ([self elementCount] == 0) {
        // nothing to close
        return;
    }
    if ([self elementAtIndex:[self elementCount] - 1].type == kCGPathElementCloseSubpath) {
        // don't close the path multiple times, otherwise our cache
        // will record incorrect cachedElementCount.
        // we can't check isClosed here, as the UIBezierPath might contain
        // multiple subpaths, some of which might be closed and have flipped our isClosed cache.
        return;
    }

    UIBezierPathProperties *props = [self pathProperties];
    [props resetSubpathRangeCount];
    props.isClosed = YES;
    props.knowsIfClosed = YES;
    props.lastAddedElementWasMoveTo = NO;
    props.bezierPathByFlatteningPath = nil;
    if ([self isEmpty] || props.isFlat) {
        props.isFlat = YES;
    }
    if (props.cachedElementCount) {
        props.cachedElementCount = props.cachedElementCount + 1;
    }
    if (props.hasLastPoint && props.hasFirstPoint) {
        props.lastPoint = props.firstPoint;
    } else {
        props.hasLastPoint = NO;
    }
    [self swizzle_closePath];
}
- (void)swizzle_arcWithCenter:(CGPoint)center radius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle clockwise:(BOOL)clockwise
{
    UIBezierPathProperties *props = [self pathProperties];
    [props resetSubpathRangeCount];
    props.lastAddedElementWasMoveTo = NO;
    props.bezierPathByFlatteningPath = nil;
    if ([self isEmpty] || props.isFlat) {
        props.isFlat = NO;
    }
    if (props.cachedElementCount) {
        props.cachedElementCount = props.cachedElementCount + 1;
    }
    [self swizzle_arcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:clockwise];
}
- (void)swizzle_removeAllPoints
{
    UIBezierPathProperties *props = [self pathProperties];
    [props resetSubpathRangeCount];
    props.lastAddedElementWasMoveTo = NO;
    props.bezierPathByFlatteningPath = nil;
    [self swizzle_removeAllPoints];
    props.cachedElementCount = 0;
    props.tangentAtEnd = 0;
    props.hasLastPoint = NO;
    props.hasFirstPoint = NO;
    props.isClosed = NO;
    props.knowsIfClosed = YES;
    if ([self isEmpty] || props.isFlat) {
        props.isFlat = YES;
    }
}
- (void)swizzle_appendPath:(UIBezierPath *)bezierPath
{
    UIBezierPathProperties *props = [self pathProperties];
    [props resetSubpathRangeCount];
    props.lastAddedElementWasMoveTo = NO;
    UIBezierPathProperties *bezierPathProps = [bezierPath pathProperties];
    props.bezierPathByFlatteningPath = nil;
    if (([self isEmpty] && bezierPathProps.isFlat) || (props.isFlat && bezierPathProps.isFlat)) {
        props.isFlat = YES;
    } else {
        props.isFlat = NO;
    }
    [self swizzle_appendPath:bezierPath];
    props.hasLastPoint = bezierPathProps.hasLastPoint;
    props.lastPoint = bezierPathProps.lastPoint;
    props.tangentAtEnd = bezierPathProps.tangentAtEnd;
    props.cachedElementCount = 0;
}
- (UIBezierPath *)swizzle_copy
{
    UIBezierPathProperties *props = [self pathProperties];
    UIBezierPath *ret = [self swizzle_copy];
    CGMutablePathRef pathRef = CGPathCreateMutableCopy(self.CGPath);
    ret.CGPath = pathRef;
    CGPathRelease(pathRef);
    UIBezierPathProperties *retProps = [ret pathProperties];
    retProps.lastAddedElementWasMoveTo = props.lastAddedElementWasMoveTo;
    retProps.isFlat = props.isFlat;
    retProps.hasLastPoint = props.hasLastPoint;
    retProps.lastPoint = props.lastPoint;
    retProps.hasFirstPoint = props.hasFirstPoint;
    retProps.firstPoint = props.firstPoint;
    retProps.tangentAtEnd = props.tangentAtEnd;
    retProps.cachedElementCount = props.cachedElementCount;
    retProps.isClosed = props.isClosed;
    if (props.userInfo) {
        [ret.userInfo addEntriesFromDictionary:[props userInfo]];
    }
    return ret;
}

+ (UIBezierPath *)swizzle_bezierPathWithRect:(CGRect)rect
{
    UIBezierPath *path = [UIBezierPath swizzle_bezierPathWithRect:rect];
    UIBezierPathProperties *props = [path pathProperties];
    props.isFlat = YES;
    props.knowsIfClosed = YES;
    props.isClosed = YES;
    return path;
}

+ (UIBezierPath *)swizzle_bezierPathWithOvalInRect:(CGRect)rect
{
    UIBezierPath *path = [UIBezierPath swizzle_bezierPathWithOvalInRect:rect];
    UIBezierPathProperties *props = [path pathProperties];
    props.isFlat = NO;
    props.knowsIfClosed = YES;
    props.isClosed = YES;
    return path;
}

+ (UIBezierPath *)swizzle_bezierPathWithRoundedRect:(CGRect)rect byRoundingCorners:(UIRectCorner)corners cornerRadii:(CGSize)cornerRadii
{
    UIBezierPath *path = [UIBezierPath swizzle_bezierPathWithRoundedRect:rect byRoundingCorners:corners cornerRadii:cornerRadii];
    UIBezierPathProperties *props = [path pathProperties];
    props.isFlat = NO;
    props.knowsIfClosed = YES;
    props.isClosed = YES;
    return path;
}

+ (UIBezierPath *)swizzle_bezierPathWithRoundedRect:(CGRect)rect cornerRadius:(CGFloat)cornerRadii
{
    UIBezierPath *path = [UIBezierPath swizzle_bezierPathWithRoundedRect:rect cornerRadius:cornerRadii];
    UIBezierPathProperties *props = [path pathProperties];
    props.isFlat = NO;
    props.knowsIfClosed = YES;
    props.isClosed = YES;
    return path;
}


+ (void)load
{
    @autoreleasepool {
        NSError *error = nil;
        [UIBezierPath mmpb_swizzleClassMethod:@selector(bezierPathWithRect:)
                              withClassMethod:@selector(swizzle_bezierPathWithRect:)
                                        error:&error];
        [UIBezierPath mmpb_swizzleClassMethod:@selector(bezierPathWithOvalInRect:)
                              withClassMethod:@selector(swizzle_bezierPathWithOvalInRect:)
                                        error:&error];
        [UIBezierPath mmpb_swizzleClassMethod:@selector(bezierPathWithRoundedRect:byRoundingCorners:cornerRadii:)
                              withClassMethod:@selector(swizzle_bezierPathWithRoundedRect:byRoundingCorners:cornerRadii:)
                                        error:&error];
        [UIBezierPath mmpb_swizzleClassMethod:@selector(bezierPathWithRoundedRect:cornerRadius:)
                              withClassMethod:@selector(swizzle_bezierPathWithRoundedRect:cornerRadius:)
                                        error:&error];
        [UIBezierPath mmpb_swizzleMethod:@selector(moveToPoint:)
                              withMethod:@selector(swizzle_moveToPoint:)
                                   error:&error];
        [UIBezierPath mmpb_swizzleMethod:@selector(addLineToPoint:)
                              withMethod:@selector(swizzle_addLineToPoint:)
                                   error:&error];
        [UIBezierPath mmpb_swizzleMethod:@selector(addCurveToPoint:controlPoint1:controlPoint2:)
                              withMethod:@selector(swizzle_addCurveToPoint:controlPoint1:controlPoint2:)
                                   error:&error];
        [UIBezierPath mmpb_swizzleMethod:@selector(addQuadCurveToPoint:controlPoint:)
                              withMethod:@selector(swizzle_quadCurveToPoint:controlPoint:)
                                   error:&error];
        [UIBezierPath mmpb_swizzleMethod:@selector(closePath)
                              withMethod:@selector(swizzle_closePath)
                                   error:&error];
        [UIBezierPath mmpb_swizzleMethod:@selector(addArcWithCenter:radius:startAngle:endAngle:clockwise:)
                              withMethod:@selector(swizzle_arcWithCenter:radius:startAngle:endAngle:clockwise:)
                                   error:&error];
        [UIBezierPath mmpb_swizzleMethod:@selector(removeAllPoints)
                              withMethod:@selector(swizzle_removeAllPoints)
                                   error:&error];
        [UIBezierPath mmpb_swizzleMethod:@selector(appendPath:)
                              withMethod:@selector(swizzle_appendPath:)
                                   error:&error];
        [UIBezierPath mmpb_swizzleMethod:@selector(copy)
                              withMethod:@selector(swizzle_copy)
                                   error:&error];
        [UIBezierPath mmpb_swizzleMethod:@selector(initWithCoder:)
                              withMethod:@selector(swizzle_initWithCoder:)
                                   error:&error];
        [UIBezierPath mmpb_swizzleMethod:@selector(encodeWithCoder:)
                              withMethod:@selector(swizzle_encodeWithCoder:)
                                   error:&error];
        [UIBezierPath mmpb_swizzleMethod:@selector(applyTransform:)
                              withMethod:@selector(ahmed_swizzle_applyTransform:)
                                   error:&error];
        [UIBezierPath mmpb_swizzleMethod:@selector(dealloc)
                              withMethod:@selector(ahmed_swizzle_dealloc)
                                   error:&error];
        [UIBezierPath mmpb_swizzleClassMethod:@selector(bezierPathWithCGPath:)
                              withClassMethod:@selector(swizzle_bezierPathWithCGPath:)
                                        error:&error];
    }
}


/**
 * if a curve, the ctrlpoint should be point1, and end point is point2
 * if line, prev point is point1, and end point is point2
 */
- (CGFloat)calculateTangentBetween:(CGPoint)point1 andPoint:(CGPoint)point2
{
    return atan2f(point1.y - point2.y, point1.x - point2.x);
}

- (NSRange)subpathRangeForElement:(NSInteger)elementIndex
{
    NSRange cachedRange = [[self pathProperties] subpathRangeForElementIndex:elementIndex];

    if (cachedRange.location != NSNotFound) {
        return cachedRange;
    }

    NSInteger firstIndex = elementIndex;
    NSInteger lastIndex = elementIndex;

    if ([self elementAtIndex:elementIndex].type == kCGPathElementMoveToPoint) {
        if (elementIndex == [self elementCount] - 1) {
            // the move to is the last element in the path
            return NSMakeRange(elementIndex, 1);
        } else {
            lastIndex = elementIndex + 1;
        }
    }

    while ([self elementAtIndex:firstIndex].type != kCGPathElementMoveToPoint && firstIndex > 0) {
        firstIndex -= 1;
    }

    while ([self elementAtIndex:lastIndex].type != kCGPathElementMoveToPoint &&
           [self elementAtIndex:lastIndex].type != kCGPathElementCloseSubpath &&
           lastIndex < [self elementCount] - 1) {
        lastIndex += 1;
    }

    if ([self elementAtIndex:lastIndex].type == kCGPathElementMoveToPoint) {
        lastIndex -= 1;
    }

    NSRange subpathRange = NSMakeRange(firstIndex, lastIndex - firstIndex + 1);

    [[self pathProperties] cacheSubpathRange:subpathRange];

    return subpathRange;
}

- (BOOL)changesPositionDuringElement:(NSInteger)elementIndex
{
    ElementPositionChange cache = [[self pathProperties] cachedElementIndexDoesChangePosition:elementIndex];

    if (cache != kPositionChangeUnknown) {
        return cache == kPositionChangeYes ? YES : NO;
    }

    BOOL ret = NO;
    CGPathElement ele = [self elementAtIndex:elementIndex];

    BOOL (^movesSincePrev)(CGPathElement, CGPathElement) = ^(CGPathElement prevEle, CGPathElement ele) {
      NSInteger numPrevPoints = [UIBezierPath numberOfPointsForElement:prevEle];
      for (int i = 0; i < [UIBezierPath numberOfPointsForElement:ele]; i++) {
          // we can compare to [0] since we're asking if /all/ points are equal.
          if (!CGPointEqualToPoint(ele.points[i], prevEle.points[numPrevPoints - 1])) {
              return NO;
          }
      }
      return YES;
    };

    if (ele.type == kCGPathElementMoveToPoint) {
        ret = NO;
    } else if (elementIndex == 0) {
        // sanity check, element 0 should always be a moveTo element
        ret = NO;
    } else if (ele.type == kCGPathElementCloseSubpath) {
        NSRange rng = [self subpathRangeForElement:elementIndex];
        CGPathElement last = [self elementAtIndex:elementIndex - 1];
        CGPathElement first = [self elementAtIndex:rng.location];

        ret = !movesSincePrev(last, first);
    } else {
        CGPathElement previous = [self elementAtIndex:elementIndex - 1];
        ret = !movesSincePrev(previous, ele);
    }

    [[self pathProperties] cacheElementIndex:elementIndex changesPosition:ret];

    return ret;
}

@end
