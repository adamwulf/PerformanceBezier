//
//  UIBezierPath+NSOSX.m
//  PaintingSample
//
//  Created by Adam Wulf on 10/5/12.
//
//

#import "UIBezierPath+NSOSX.h"
#import "JRSwizzle.h"
#import "UIBezierPath+NSOSX_Private.h"
#import "UIBezierPath+Performance_Private.h"
#import "UIBezierPath+Performance.h"
#import "UIBezierPath+Uncached.h"
#import "UIBezierPath+Util.h"
#import <objc/runtime.h>

static char ELEMENT_ARRAY;

@implementation UIBezierPath (NSOSX)


#pragma mark - Properties

/**
 * this is a property on the category, as described in:
 * https://github.com/techpaa/iProperties
 *
 *
 * this array is for private PerformanceBezier use only
 *
 * Since iOS doesn't allow for index lookup of CGPath elements (only option is CGPathApply)
 * this array will cache the elements after they've been looked up once
 */
- (void)freeCurrentElementCacheArray
{
    NSMutableArray *currentArray = objc_getAssociatedObject(self, &ELEMENT_ARRAY);
    if ([currentArray count]) {
        while ([currentArray count]) {
            NSValue *val = [currentArray lastObject];
            CGPathElement *element = [val pointerValue];
            free(element->points);
            free(element);
            [currentArray removeLastObject];
        }
    }
    objc_setAssociatedObject(self, &ELEMENT_ARRAY, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void)setElementCacheArray:(NSMutableArray *)_elementCacheArray
{
    [self freeCurrentElementCacheArray];
    NSMutableArray *newArray = [NSMutableArray array];
    for (NSValue *val in _elementCacheArray) {
        CGPathElement *element = [val pointerValue];
        CGPathElement *copiedElement = [UIBezierPath copyCGPathElement:element];
        [newArray addObject:[NSValue valueWithPointer:copiedElement]];
    }
    objc_setAssociatedObject(self, &ELEMENT_ARRAY, newArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSMutableArray *)elementCacheArray
{
    NSMutableArray *ret = objc_getAssociatedObject(self, &ELEMENT_ARRAY);
    if (!ret) {
        ret = [NSMutableArray array];
        self.elementCacheArray = ret;
    }
    return ret;
}


#pragma mark - UIBezierPath

/**
 * returns the CGPathElement at the specified index, optionally
 * also returning the elements points in the 2nd parameter
 *
 * this method is meant to mimic UIBezierPath's method of the same name
 */
- (CGPathElement)elementAtIndex:(NSInteger)askingForIndex associatedPoints:(CGPoint[])points
{
    __block BOOL didReturn = NO;
    __block CGPathElement returnVal;
    if (askingForIndex < [self.elementCacheArray count]) {
        didReturn = YES;
        returnVal = *(CGPathElement *)[[self.elementCacheArray objectAtIndex:askingForIndex] pointerValue];
#ifdef MMPreventBezierPerformance
        [self simulateNoBezierCaching];
#endif
    } else {
        __block UIBezierPath *this = self;
        [self iteratePathWithBlock:^(CGPathElement element, NSUInteger currentIndex) {
          int numberInCache = (int)[this.elementCacheArray count];
          if (!didReturn || currentIndex == [this.elementCacheArray count]) {
              if (currentIndex == numberInCache) {
                  [this.elementCacheArray addObject:[NSValue valueWithPointer:[UIBezierPath copyCGPathElement:&element]]];
              }
              if (currentIndex == askingForIndex) {
                  returnVal = *(CGPathElement *)[[this.elementCacheArray objectAtIndex:askingForIndex] pointerValue];
                  didReturn = YES;
              }
          }
        }];
    }

    if (!didReturn) {
        // something went wrong, reset our properties and throw an exception
        [self resetPathProperties];

        @throw [NSException exceptionWithName:BezierElementCacheException reason:nil userInfo:nil];
    }

    NSAssert(didReturn, @"could not find index %@ in path", @(askingForIndex));

    if (points) {
        for (int i = 0; i < [UIBezierPath numberOfPointsForElement:returnVal]; i++) {
            points[i] = returnVal.points[i];
        }
    }
    return returnVal;
}


/**
 * returns the CGPathElement at the specified index
 *
 * this method is meant to mimic UIBezierPath's method of the same name
 */
- (CGPathElement)elementAtIndex:(NSInteger)index
{
    return [self elementAtIndex:index associatedPoints:NULL];
}


/**
 * updates the point in the path with the new input points
 *
 * TODO: this method is entirely untested
 */
- (void)setAssociatedPoints:(CGPoint[])points atIndex:(NSInteger)index
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:[NSNumber numberWithInteger:index] forKey:@"index"];
    [params setObject:[NSValue valueWithPointer:points] forKey:@"points"];
    const void *_Nullable paramPtr = CFBridgingRetain(params);
    CGPathApply(self.CGPath, (void *_Nullable) paramPtr, updatePathElementAtIndex);
    CFRelease(paramPtr);
}
//
// helper function for the setAssociatedPoints: method
void updatePathElementAtIndex(void *info, const CGPathElement *element)
{
    NSMutableDictionary *params = (__bridge NSMutableDictionary *)info;
    int currentIndex = 0;
    if ([params objectForKey:@"curr"]) {
        currentIndex = [[params objectForKey:@"curr"] intValue] + 1;
    }
    if (currentIndex == [[params objectForKey:@"index"] intValue]) {
        CGPoint *points = [[params objectForKey:@"points"] pointerValue];
        for (int i = 0; i < [UIBezierPath numberOfPointsForElement:*element]; i++) {
            element->points[i] = points[i];
        }
        CGPathElement *returnVal = [UIBezierPath copyCGPathElement:(CGPathElement *)element];
        [params setObject:[NSValue valueWithPointer:returnVal] forKey:@"element"];
    }
    [params setObject:[NSNumber numberWithInt:currentIndex] forKey:@"curr"];
}

/**
 * Returns the bounding box containing all points in a graphics path.
 * The bounding box is the smallest rectangle completely enclosing
 * all points in the path, including control points for Bézier and
 * quadratic curves.
 *
 * this method is meant to mimic UIBezierPath's method of the same name
 */
- (CGRect)controlPointBounds
{
    return CGPathGetBoundingBox(self.CGPath);
}


- (NSInteger)elementCount
{
    UIBezierPathProperties *props = [self pathProperties];
    if (props.cachedElementCount) {
#ifdef MMPreventBezierPerformance
        [self simulateNoBezierCaching];
#endif
        return props.cachedElementCount;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:[NSNumber numberWithInteger:0] forKey:@"count"];
    [params setObject:self forKey:@"self"];
    const void *_Nullable paramPtr = CFBridgingRetain(params);
    CGPathApply(self.CGPath, (void *_Nullable) paramPtr, countPathElement);
    CFRelease(paramPtr);
    NSInteger ret = [[params objectForKey:@"count"] integerValue];
    props.cachedElementCount = ret;
    return ret;
}
// helper function
void countPathElement(void *info, const CGPathElement *element)
{
    NSMutableDictionary *params = (__bridge NSMutableDictionary *)info;
    UIBezierPath *this = [params objectForKey:@"self"];
    NSInteger count = [[params objectForKey:@"count"] integerValue];
    [params setObject:[NSNumber numberWithInteger:(count + 1)] forKey:@"count"];
    if (count == [this.elementCacheArray count]) {
        [this.elementCacheArray addObject:[NSValue valueWithPointer:[UIBezierPath copyCGPathElement:(CGPathElement *)element]]];
    }
}

- (void)iteratePathWithBlock:(void (^)(CGPathElement element, NSUInteger idx))block
{
    void (^copiedBlock)(CGPathElement element) = [block copy];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:copiedBlock forKey:@"block"];
    const void *_Nullable paramPtr = CFBridgingRetain(params);
    CGPathApply(self.CGPath, (void *_Nullable) paramPtr, blockWithElement);
    CFRelease(paramPtr);
}

// helper function
static void blockWithElement(void *info, const CGPathElement *element)
{
    NSMutableDictionary *params = (__bridge NSMutableDictionary *)info;
    void (^block)(CGPathElement element, NSUInteger idx) = [params objectForKey:@"block"];
    NSUInteger index = [[params objectForKey:@"index"] unsignedIntegerValue];
    block(*element, index);
    [params setObject:@(index + 1) forKey:@"index"];
}

#pragma mark - Flat


#pragma mark - Properties


/**
 * this is a property on the category, as described in:
 * https://github.com/techpaa/iProperties
 */
- (void)setIsFlat:(BOOL)isFlat
{
    [self pathProperties].isFlat = isFlat;
}

/**
 * return YES if this bezier path is made up of only
 * moveTo, closePath, and lineTo elements
 *
 * TODO
 * this method helps caching flattened paths internally
 * to this category, but is not yet fit for public use.
 *
 * detecting when this path is flat would mean we'd have
 * to also swizzle the constructors to bezier paths
 */
- (BOOL)isFlat
{
    return [self pathProperties].isFlat;
}

#pragma mark - Helper

/**
 * returns the length of the points array for the input
 * CGPathElement element
 */
+ (NSInteger)numberOfPointsForElement:(CGPathElement)element
{
    NSInteger nPoints = 0;
    switch (element.type) {
        case kCGPathElementMoveToPoint:
            nPoints = 1;
            break;
        case kCGPathElementAddLineToPoint:
            nPoints = 1;
            break;
        case kCGPathElementAddQuadCurveToPoint:
            nPoints = 2;
            break;
        case kCGPathElementAddCurveToPoint:
            nPoints = 3;
            break;
        case kCGPathElementCloseSubpath:
            nPoints = 0;
            break;
        default:
            nPoints = 0;
    }
    return nPoints;
}


/**
 * copies the input CGPathElement
 *
 * TODO: I currently never free the memory assigned for the points array
 * https://github.com/adamwulf/DrawKit-iOS/issues/4
 */
+ (CGPathElement *)copyCGPathElement:(CGPathElement *)element
{
    CGPathElement *ret = malloc(sizeof(CGPathElement));
    if (!ret) {
        @throw [NSException exceptionWithName:@"Memory Exception" reason:@"can't malloc" userInfo:nil];
    }
    NSInteger numberOfPoints = [UIBezierPath numberOfPointsForElement:*element];
    if (numberOfPoints) {
        ret->points = malloc(sizeof(CGPoint) * numberOfPoints);
    } else {
        ret->points = NULL;
    }
    ret->type = element->type;

    for (int i = 0; i < numberOfPoints; i++) {
        ret->points[i] = element->points[i];
    }
    return ret;
}


#pragma mark - Swizzling

///////////////////////////////////////////////////////////////////////////
//
// All of these methods are to listen to UIBezierPath method calls
// so that we can add new functionality on top of them without
// changing any of the default behavior.
//
// These methods help maintain:
// 1. cachedElementCount
// 2. elementCacheArray
// 3. keeping cache's valid across copying


- (void)nsosx_swizzle_removeAllPoints
{
    [self setElementCacheArray:nil];
    [self nsosx_swizzle_removeAllPoints];
}

- (UIBezierPath *)nsosx_swizzle_copy
{
    UIBezierPath *ret = [self nsosx_swizzle_copy];
    // note, when setting the array here, it will actually be making
    // a mutable copy of the input array, so the copied
    // path will have its own version.
    [ret setElementCacheArray:self.elementCacheArray];
    return ret;
}
- (void)nsosx_swizzle_applyTransform:(CGAffineTransform)transform
{
    [self setElementCacheArray:nil];
    [self pathProperties].hasLastPoint = NO;
    [self pathProperties].hasFirstPoint = NO;
    [self nsosx_swizzle_applyTransform:transform];
}


- (void)nsosx_swizzle_dealloc
{
    [self freeCurrentElementCacheArray];
    [self nsosx_swizzle_dealloc];
}

+ (void)load
{
    @autoreleasepool {
        NSError *error = nil;
        [UIBezierPath mmpb_swizzleMethod:@selector(removeAllPoints)
                              withMethod:@selector(nsosx_swizzle_removeAllPoints)
                                   error:&error];
        [UIBezierPath mmpb_swizzleMethod:@selector(applyTransform:)
                              withMethod:@selector(nsosx_swizzle_applyTransform:)
                                   error:&error];
        [UIBezierPath mmpb_swizzleMethod:@selector(copy)
                              withMethod:@selector(nsosx_swizzle_copy)
                                   error:&error];
        [UIBezierPath mmpb_swizzleMethod:NSSelectorFromString(@"dealloc")
                              withMethod:@selector(nsosx_swizzle_dealloc)
                                   error:&error];
    }
}


@end
