//
//  UIBezierPath+Performance.m
//  DrawKit-iOS
//
//  Created by Adam Wulf on 1/31/15.
//  Copyright (c) 2015 Milestone Made, LLC. All rights reserved.
//

#import "UIBezierPath+Performance.h"
#import "UIBezierPath+Performance_Private.h"
#import "UIBezierPath+FirstLast.h"
#import "UIBezierPath+NSOSX.h"
#import <objc/runtime.h>
#import "JRSwizzle.h"

static char BEZIER_PROPERTIES;

@implementation UIBezierPath (Performance)

-(UIBezierPathProperties*) pathProperties{
    UIBezierPathProperties* props = objc_getAssociatedObject(self, &BEZIER_PROPERTIES);
    if(!props){
        props = [[[UIBezierPathProperties alloc] init] autorelease];
        objc_setAssociatedObject(self, &BEZIER_PROPERTIES, props, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return props;
}

-(void)setTangentAtEnd:(CGPoint)tangent{
    [self pathProperties].tangentAtEnd = tangent;
}

-(CGPoint)lastPoint{
    UIBezierPathProperties* props = [self pathProperties];
    if(!props.hasLastPoint){
        props.hasLastPoint = YES;
        props.lastPoint = [self lastPointCalculated];
    }
    return props.lastPoint;
}
-(CGPoint)firstPoint{
    UIBezierPathProperties* props = [self pathProperties];
    if(!props.hasFirstPoint){
        props.hasFirstPoint = YES;
        props.firstPoint = [self firstPointCalculated];
    }
    return props.firstPoint;
}
-(BOOL) isClosed{
    UIBezierPathProperties* props = [self pathProperties];
    if(!props.knowsIfClosed){
        // we dont know if the path is closed, so
        // find a close element if we have one
        [self iteratePathWithBlock:^(CGPathElement ele){
            if(ele.type == kCGPathElementCloseSubpath){
                props.isClosed = YES;
            }
        }];
        props.knowsIfClosed = YES;
    }
    return props.isClosed;
}
-(CGPoint) tangentAtEnd{
    return [self pathProperties].tangentAtEnd;
}

/**
 * this is a property on the category, as described in:
 * https://github.com/techpaa/iProperties
 */
-(void)setBezierPathByFlatteningPath:(UIBezierPath *)bezierPathByFlatteningPath{
    [self pathProperties].bezierPathByFlatteningPath = bezierPathByFlatteningPath;
}



/**
 * this is a property on the category, as described in:
 * https://github.com/techpaa/iProperties
 *
 *
 * this is for internal DrawKit use only
 *
 * Since iOS doesn't allow a quick lookup for element count,
 * this property will act as a cache for the element count after
 * it has been calculated once
 */
-(void)setCachedElementCount:(NSInteger)_cachedElementCount{
    [self pathProperties].cachedElementCount = _cachedElementCount;
}

-(NSInteger)cachedElementCount{
    return [self pathProperties].cachedElementCount;
}




-(void) fillBezier:(CGPoint[4])bezier forElement:(NSInteger)elementIndex{
    if(elementIndex >= [self elementCount] || elementIndex < 0){
        @throw [NSException exceptionWithName:@"BezierElementException" reason:@"Element index is out of range" userInfo:nil];
    }
    if(elementIndex == 0){
        bezier[0] = self.firstPoint;
        bezier[1] = self.firstPoint;
        bezier[2] = self.firstPoint;
        bezier[3] = self.firstPoint;
        return;
    }
    
    CGPathElement previousElement = [self elementAtIndex:elementIndex-1];
    CGPathElement thisElement = [self elementAtIndex:elementIndex];
    
    if(previousElement.type == kCGPathElementMoveToPoint ||
       previousElement.type == kCGPathElementAddLineToPoint){
        bezier[0] = previousElement.points[0];
    }else if(previousElement.type == kCGPathElementAddQuadCurveToPoint){
        bezier[0] = previousElement.points[1];
    }else if(previousElement.type == kCGPathElementAddCurveToPoint){
        bezier[0] = previousElement.points[2];
    }
    
    if(thisElement.type == kCGPathElementCloseSubpath){
        bezier[1] = bezier[0];
        bezier[2] = self.firstPoint;
        bezier[3] = self.firstPoint;
    }else if (thisElement.type == kCGPathElementMoveToPoint ||
              thisElement.type == kCGPathElementAddLineToPoint){
        bezier[1] = bezier[0];
        bezier[2] = thisElement.points[0];
        bezier[3] = thisElement.points[0];
    }else if (thisElement.type == kCGPathElementAddQuadCurveToPoint){
        bezier[1] = thisElement.points[0];
        bezier[2] = thisElement.points[0];
        bezier[3] = thisElement.points[1];
    }else if (thisElement.type == kCGPathElementAddCurveToPoint){
        bezier[1] = thisElement.points[0];
        bezier[2] = thisElement.points[1];
        bezier[3] = thisElement.points[2];
    }
}

- (CGPoint) tangentOnPathAtElement:(NSInteger)elementIndex andTValue:(CGFloat)tVal{
    if(elementIndex >= [self elementCount] || elementIndex < 0){
        @throw [NSException exceptionWithName:@"BezierElementException" reason:@"Element index is out of range" userInfo:nil];
    }
    if(elementIndex == 0){
        return self.firstPoint;
    }
    
    CGPoint bezier[4];
    
    [self fillBezier:bezier forElement:elementIndex];
    return [UIBezierPath tangentAtT:tVal forBezier:bezier];
}



+(CGPoint) pointAtT:(CGFloat)t forBezier:(CGPoint*)bez{
    return bezierPointAtT(bez, t);
}

+(CGPoint) tangentAtT:(CGFloat)t forBezier:(CGPoint*)bez{
    return bezierTangentAtT(bez, t);
}





#pragma mark - Helper


// primary algorithm from:
// http://stackoverflow.com/questions/4089443/find-the-tangent-of-a-point-on-a-cubic-bezier-curve-on-an-iphone
inline CGPoint bezierTangentAtT(const CGPoint bez[4], CGFloat t)
{
    return CGPointMake(bezierTangent(t, bez[0].x, bez[1].x, bez[2].x, bez[3].x),
                       bezierTangent(t, bez[0].y, bez[1].y, bez[2].y, bez[3].y));
}
inline CGFloat bezierTangent(CGFloat t, CGFloat a, CGFloat b, CGFloat c, CGFloat d)
{
    CGFloat C1 = ( d - (3.0 * c) + (3.0 * b) - a );
    CGFloat C2 = ( (3.0 * c) - (6.0 * b) + (3.0 * a) );
    CGFloat C3 = ( (3.0 * b) - (3.0 * a) );
    return ( ( 3.0 * C1 * t* t ) + ( 2.0 * C2 * t ) + C3 );
}


/**
 * returns the shortest distance from a point to a line
 */
CGFloat	distanceOfPointToLine(CGPoint point, CGPoint start, CGPoint end){
    CGPoint v = CGPointMake(end.x - start.x, end.y - start.y);
    CGPoint w = CGPointMake(point.x - start.x, point.y - start.y);
    CGFloat c1 = dotProduct(w, v);
    CGFloat c2 = dotProduct(v, v);
    CGFloat d;
    if (c1 <= 0) {
        d = distance(point, start);
    }
    else if (c2 <= c1) {
        d = distance(point, end);
    }
    else {
        CGFloat b = c1 / c2;
        CGPoint Pb = CGPointMake(start.x + b * v.x, start.y + b * v.y);
        d = distance(point, Pb);
    }
    return d;
}
/**
 * returns the distance between two points
 */
CGFloat distance(const CGPoint p1, const CGPoint p2) {
    return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));
}
/**
 * returns the dot product of two coordinates
 */
CGFloat dotProduct(const CGPoint p1, const CGPoint p2) {
    return p1.x * p2.x + p1.y * p2.y;
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


-(void) ahmed_swizzle_dealloc{
    objc_setAssociatedObject(self, &BEZIER_PROPERTIES, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self ahmed_swizzle_dealloc];
}

- (id)swizzle_initWithCoder:(NSCoder *)decoder{
    self = [self swizzle_initWithCoder:decoder];
    UIBezierPathProperties* props = [decoder decodeObjectForKey:@"pathProperties"];
    objc_setAssociatedObject(self, &BEZIER_PROPERTIES, props, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return self;
}

-(void) swizzle_encodeWithCoder:(NSCoder *)aCoder{
    [self swizzle_encodeWithCoder:aCoder];
    [aCoder encodeObject:self.pathProperties forKey:@"pathProperties"];
}
-(void) ahmed_swizzle_applyTransform:(CGAffineTransform)transform{
    // reset our path properties
    BOOL isClosed = [self pathProperties].isClosed;
    UIBezierPathProperties* props = [[[UIBezierPathProperties alloc] init] autorelease];
    props.isClosed = isClosed;
    objc_setAssociatedObject(self, &BEZIER_PROPERTIES, props, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self ahmed_swizzle_applyTransform:transform];
}

-(void) swizzle_moveToPoint:(CGPoint)point{
    UIBezierPathProperties* props = [self pathProperties];
    props.bezierPathByFlatteningPath = nil;
    BOOL isEmpty = [self isEmpty];
    if(isEmpty || props.isFlat){
        props.isFlat = YES;
    }
    if(isEmpty){
        props.hasFirstPoint = YES;
        props.firstPoint = point;
        props.cachedElementCount = 1;
    }else if(props.cachedElementCount){
        if(!props.lastAddedElementWasMoveTo){
            // when adding multiple moveTo elements to a path
            // in a row, iOS actually just modifies the last moveTo
            // instead of having tons of useless moveTos
            props.cachedElementCount = props.cachedElementCount + 1;
        }else if(props.cachedElementCount == 1){
            // otherwise, the first and only point was
            // a move to, so update our first point
            props.firstPoint = point;
        }
    }
    props.hasLastPoint = YES;
    props.lastPoint = point;
    props.tangentAtEnd = CGPointZero;
    props.lastAddedElementWasMoveTo = YES;
    [self swizzle_moveToPoint:point];
}
-(void) swizzle_addLineToPoint:(CGPoint)point{
    UIBezierPathProperties* props = [self pathProperties];
    props.lastAddedElementWasMoveTo = NO;
    props.bezierPathByFlatteningPath = nil;
    if([self isEmpty] || props.isFlat){
        props.isFlat = YES;
    }
    if(props.cachedElementCount){
        props.cachedElementCount = props.cachedElementCount + 1;
    }
    props.tangentAtEnd = CGPointMake(props.lastPoint.x - point.x, props.lastPoint.y - point.y);
    props.hasLastPoint = YES;
    props.lastPoint = point;
    [self swizzle_addLineToPoint:point];
}
-(void) swizzle_addCurveToPoint:(CGPoint)point controlPoint1:(CGPoint)ctrl1 controlPoint2:(CGPoint)ctrl2{
    UIBezierPathProperties* props = [self pathProperties];
    props.lastAddedElementWasMoveTo = NO;
    props.bezierPathByFlatteningPath = nil;
    if([self isEmpty] || props.isFlat){
        props.isFlat = NO;
    }
    if(props.cachedElementCount){
        props.cachedElementCount = props.cachedElementCount + 1;
    }
    props.tangentAtEnd = CGPointMake(ctrl2.x - point.x, ctrl2.y - point.y);
    props.hasLastPoint = YES;
    props.lastPoint = point;
    [self swizzle_addCurveToPoint:point controlPoint1:ctrl1 controlPoint2:ctrl2];
}
-(void) swizzle_quadCurveToPoint:(CGPoint)point controlPoint:(CGPoint)ctrl1{
    UIBezierPathProperties* props = [self pathProperties];
    props.lastAddedElementWasMoveTo = NO;
    props.bezierPathByFlatteningPath = nil;
    if([self isEmpty] || props.isFlat){
        props.isFlat = NO;
    }
    if(props.cachedElementCount){
        props.cachedElementCount = props.cachedElementCount + 1;
    }
    props.hasLastPoint = YES;
    props.lastPoint = point;
    props.tangentAtEnd = CGPointMake(ctrl1.x - point.x, ctrl1.y - point.y);
    [self swizzle_quadCurveToPoint:point controlPoint:ctrl1];
}
-(void) swizzle_closePath{
    UIBezierPathProperties* props = [self pathProperties];
    props.isClosed = YES;
    props.knowsIfClosed = YES;
    props.lastAddedElementWasMoveTo = NO;
    props.bezierPathByFlatteningPath = nil;
    if([self isEmpty] || props.isFlat){
        props.isFlat = YES;
    }
    if(props.cachedElementCount){
        props.cachedElementCount = props.cachedElementCount + 1;
    }
    if(props.hasLastPoint && props.hasFirstPoint){
        props.lastPoint = props.firstPoint;
    }else{
        props.hasLastPoint = NO;
    }
    [self swizzle_closePath];
}
-(void)swizzle_arcWithCenter:(CGPoint)center radius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle clockwise:(BOOL)clockwise{
    UIBezierPathProperties* props = [self pathProperties];
    props.lastAddedElementWasMoveTo = NO;
    props.bezierPathByFlatteningPath = nil;
    if([self isEmpty] || props.isFlat){
        props.isFlat = NO;
    }
    if(props.cachedElementCount){
        props.cachedElementCount = props.cachedElementCount + 1;
    }
    [self swizzle_arcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:clockwise];
}
-(void) swizzle_removeAllPoints{
    UIBezierPathProperties* props = [self pathProperties];
    props.lastAddedElementWasMoveTo = NO;
    props.bezierPathByFlatteningPath = nil;
    [self swizzle_removeAllPoints];
    props.cachedElementCount = 0;
    props.tangentAtEnd = CGPointZero;
    props.hasLastPoint = NO;
    props.hasFirstPoint = NO;
    props.isClosed = NO;
    props.knowsIfClosed = YES;
    if([self isEmpty] || props.isFlat){
        props.isFlat = YES;
    }
}
- (void)swizzle_appendPath:(UIBezierPath *)bezierPath{
    UIBezierPathProperties* props = [self pathProperties];
    props.lastAddedElementWasMoveTo = NO;
    UIBezierPathProperties* bezierPathProps = [bezierPath pathProperties];
    props.bezierPathByFlatteningPath = nil;
    if(([self isEmpty] && bezierPathProps.isFlat) || (props.isFlat && bezierPathProps.isFlat)){
        props.isFlat = YES;
    }else{
        props.isFlat = NO;
    }
    [self swizzle_appendPath:bezierPath];
    props.hasLastPoint = bezierPathProps.hasLastPoint;
    props.lastPoint = bezierPathProps.lastPoint;
    props.tangentAtEnd = bezierPathProps.tangentAtEnd;
    props.cachedElementCount = 0;
}
-(UIBezierPath*) swizzle_copy{
    UIBezierPathProperties* props = [self pathProperties];
    UIBezierPath* ret = [self swizzle_copy];
    CGMutablePathRef pathRef = CGPathCreateMutableCopy(self.CGPath);
    ret.CGPath = pathRef;
    CGPathRelease(pathRef);
    UIBezierPathProperties* retProps = [ret pathProperties];
    retProps.lastAddedElementWasMoveTo = props.lastAddedElementWasMoveTo;
    retProps.isFlat = props.isFlat;
    retProps.hasLastPoint = props.hasLastPoint;
    retProps.lastPoint = props.lastPoint;
    retProps.hasFirstPoint = props.hasFirstPoint;
    retProps.firstPoint = props.firstPoint;
    retProps.tangentAtEnd = props.tangentAtEnd;
    retProps.cachedElementCount = props.cachedElementCount;
    retProps.isClosed = props.isClosed;
    return ret;
}

+(UIBezierPath*) swizzle_bezierPathWithRect:(CGRect)rect{
    UIBezierPath* path = [UIBezierPath swizzle_bezierPathWithRect:rect];
    UIBezierPathProperties* props = [path pathProperties];
    props.isFlat = YES;
    props.knowsIfClosed = YES;
    props.isClosed = YES;
    return path;
}

+(UIBezierPath*) swizzle_bezierPathWithOvalInRect:(CGRect)rect{
    UIBezierPath* path = [UIBezierPath swizzle_bezierPathWithOvalInRect:rect];
    UIBezierPathProperties* props = [path pathProperties];
    props.isFlat = YES;
    props.knowsIfClosed = YES;
    props.isClosed = YES;
    return path;
}

+(UIBezierPath*) swizzle_bezierPathWithRoundedRect:(CGRect)rect byRoundingCorners:(UIRectCorner)corners cornerRadii:(CGSize)cornerRadii{
    UIBezierPath* path = [UIBezierPath swizzle_bezierPathWithRoundedRect:rect byRoundingCorners:corners cornerRadii:cornerRadii];
    UIBezierPathProperties* props = [path pathProperties];
    props.isFlat = YES;
    props.knowsIfClosed = YES;
    props.isClosed = YES;
    return path;
}

+(UIBezierPath*) swizzle_bezierPathWithRoundedRect:(CGRect)rect cornerRadius:(CGFloat)cornerRadii{
    UIBezierPath* path = [UIBezierPath swizzle_bezierPathWithRoundedRect:rect cornerRadius:cornerRadii];
    UIBezierPathProperties* props = [path pathProperties];
    props.isFlat = YES;
    props.knowsIfClosed = YES;
    props.isClosed = YES;
    return path;
}



+(void)load{
    @autoreleasepool {
        NSError *error = nil;
        [UIBezierPath jr_swizzleClassMethod:@selector(bezierPathWithRect:)
                            withClassMethod:@selector(swizzle_bezierPathWithRect:)
                                      error:&error];
        [UIBezierPath jr_swizzleClassMethod:@selector(bezierPathWithOvalInRect:)
                            withClassMethod:@selector(swizzle_bezierPathWithOvalInRect:)
                                      error:&error];
        [UIBezierPath jr_swizzleClassMethod:@selector(bezierPathWithRoundedRect:byRoundingCorners:cornerRadii:)
                            withClassMethod:@selector(swizzle_bezierPathWithRoundedRect:byRoundingCorners:cornerRadii:)
                                      error:&error];
        [UIBezierPath jr_swizzleClassMethod:@selector(bezierPathWithRoundedRect:cornerRadius:)
                            withClassMethod:@selector(swizzle_bezierPathWithRoundedRect:cornerRadius:)
                                      error:&error];
        [UIBezierPath jr_swizzleMethod:@selector(moveToPoint:)
                            withMethod:@selector(swizzle_moveToPoint:)
                                 error:&error];
        [UIBezierPath jr_swizzleMethod:@selector(addLineToPoint:)
                            withMethod:@selector(swizzle_addLineToPoint:)
                                 error:&error];
        [UIBezierPath jr_swizzleMethod:@selector(addCurveToPoint:controlPoint1:controlPoint2:)
                            withMethod:@selector(swizzle_addCurveToPoint:controlPoint1:controlPoint2:)
                                 error:&error];
        [UIBezierPath jr_swizzleMethod:@selector(addQuadCurveToPoint:controlPoint:)
                            withMethod:@selector(swizzle_quadCurveToPoint:controlPoint:)
                                 error:&error];
        [UIBezierPath jr_swizzleMethod:@selector(closePath)
                            withMethod:@selector(swizzle_closePath)
                                 error:&error];
        [UIBezierPath jr_swizzleMethod:@selector(addArcWithCenter:radius:startAngle:endAngle:clockwise:)
                            withMethod:@selector(swizzle_arcWithCenter:radius:startAngle:endAngle:clockwise:)
                                 error:&error];
        [UIBezierPath jr_swizzleMethod:@selector(removeAllPoints)
                            withMethod:@selector(swizzle_removeAllPoints)
                                 error:&error];
        [UIBezierPath jr_swizzleMethod:@selector(appendPath:)
                            withMethod:@selector(swizzle_appendPath:)
                                 error:&error];
        [UIBezierPath jr_swizzleMethod:@selector(copy)
                            withMethod:@selector(swizzle_copy)
                                 error:&error];
        [UIBezierPath jr_swizzleMethod:@selector(initWithCoder:)
                            withMethod:@selector(swizzle_initWithCoder:)
                                 error:&error];
        [UIBezierPath jr_swizzleMethod:@selector(encodeWithCoder:)
                            withMethod:@selector(swizzle_encodeWithCoder:)
                                 error:&error];
        [UIBezierPath jr_swizzleMethod:@selector(applyTransform:)
                            withMethod:@selector(ahmed_swizzle_applyTransform:)
                                 error:&error];
        [UIBezierPath jr_swizzleMethod:@selector(dealloc)
                            withMethod:@selector(ahmed_swizzle_dealloc)
                                 error:&error];
    }
}



/**
 * if a curve, the ctrlpoint should be point1, and end point is point2
 * if line, prev point is point1, and end point is point2
 */
- (CGFloat) calculateTangentBetween:(CGPoint)point1 andPoint:(CGPoint)point2{
    return atan2f( point1.y - point2.y, point1.x - point2.x );
}



/**
 * calculate the point on a bezier at time t
 * where 0 < t < 1
 */
CGPoint bezierPointAtT(const CGPoint bez[4], CGFloat t)
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

@end

