//
//  UIBezierPathProperties.m
//  PerformanceBezier
//
//  Created by Adam Wulf on 2/1/15.
//  Copyright (c) 2015 Milestone Made, LLC. All rights reserved.
//

#import "UIBezierPathProperties.h"

typedef struct LengthCacheItem {
    CGFloat acceptableError;
    CGFloat length;
} LengthCacheItem;

@implementation UIBezierPathProperties {
    BOOL isFlat;
    BOOL knowsIfClosed;
    BOOL isClosed;
    BOOL hasLastPoint;
    CGPoint lastPoint;
    BOOL hasFirstPoint;
    CGPoint firstPoint;
    CGFloat tangentAtEnd;
    NSInteger cachedElementCount;
    UIBezierPath *bezierPathByFlatteningPath;
    LengthCacheItem* elementLengthCache;
    NSInteger lengthCacheCount;
    NSObject *lock;
}

@synthesize isFlat;
@synthesize knowsIfClosed;
@synthesize isClosed;
@synthesize hasLastPoint;
@synthesize lastPoint;
@synthesize tangentAtEnd;
@synthesize cachedElementCount;
@synthesize bezierPathByFlatteningPath;
@synthesize hasFirstPoint;
@synthesize firstPoint;

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)init {
    if(self = [super init]){
        elementLengthCache = nil;
        lengthCacheCount = 0;
        lock = [[NSObject alloc] init];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (!self) {
        return nil;
    }
    isFlat = [decoder decodeBoolForKey:@"pathProperties_isFlat"];
    knowsIfClosed = [decoder decodeBoolForKey:@"pathProperties_knowsIfClosed"];
    isClosed = [decoder decodeBoolForKey:@"pathProperties_isClosed"];
    hasLastPoint = [decoder decodeBoolForKey:@"pathProperties_hasLastPoint"];
    lastPoint = [decoder decodeCGPointForKey:@"pathProperties_lastPoint"];
    hasFirstPoint = [decoder decodeBoolForKey:@"pathProperties_hasFirstPoint"];
    firstPoint = [decoder decodeCGPointForKey:@"pathProperties_firstPoint"];
    tangentAtEnd = [decoder decodeFloatForKey:@"pathProperties_tangentAtEnd"];
    cachedElementCount = [decoder decodeIntegerForKey:@"pathProperties_cachedElementCount"];
    lengthCacheCount = 0;
    lock = [[NSObject alloc] init];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeBool:isFlat forKey:@"pathProperties_isFlat"];
    [aCoder encodeBool:knowsIfClosed forKey:@"pathProperties_knowsIfClosed"];
    [aCoder encodeBool:isClosed forKey:@"pathProperties_isClosed"];
    [aCoder encodeBool:hasLastPoint forKey:@"pathProperties_hasLastPoint"];
    [aCoder encodeCGPoint:lastPoint forKey:@"pathProperties_lastPoint"];
    [aCoder encodeBool:hasFirstPoint forKey:@"pathProperties_hasFirstPoint"];
    [aCoder encodeCGPoint:firstPoint forKey:@"pathProperties_firstPoint"];
    [aCoder encodeFloat:tangentAtEnd forKey:@"pathProperties_tangentAtEnd"];
    [aCoder encodeInteger:cachedElementCount forKey:@"pathProperties_cachedElementCount"];
}

// for some reason the iPad 1 on iOS 5 needs to have this
// method coded and not synthesized.
- (void)setBezierPathByFlatteningPath:(UIBezierPath *)_bezierPathByFlatteningPath
{
    if (bezierPathByFlatteningPath != _bezierPathByFlatteningPath) {
        [bezierPathByFlatteningPath release];
        [_bezierPathByFlatteningPath retain];
    }
    bezierPathByFlatteningPath = _bezierPathByFlatteningPath;
}

- (void)dealloc
{
    [bezierPathByFlatteningPath release];
    bezierPathByFlatteningPath = nil;
    
    @synchronized (lock) {
        if (lengthCacheCount > 0 && elementLengthCache){
            free(elementLengthCache);
            elementLengthCache = nil;
            lengthCacheCount = 0;
        }
    }
    
    [super dealloc];
}

/// Returns -1 if we do not have cached information for this element that matches the input acceptableError
-(CGFloat)cachedLengthForElementIndex:(NSInteger)index acceptableError:(CGFloat)error{
    @synchronized (lock) {
        if (index < 0 || index >= lengthCacheCount){
            return -1;
        }
    
        if (elementLengthCache[index].acceptableError == error){
            return elementLengthCache[index].length;
        }
    }
    
    return -1;
}

-(void)cacheLength:(CGFloat)length forElementIndex:(NSInteger)index acceptableError:(CGFloat)error{    
    @synchronized (lock) {
        if (lengthCacheCount == 0){
            const NSInteger DefaultCount = 256;
            elementLengthCache = calloc(DefaultCount, sizeof(LengthCacheItem));
            lengthCacheCount = DefaultCount;
        } else if (index >= lengthCacheCount) {
            // increase our cache size
            LengthCacheItem* oldCache = elementLengthCache;
            NSInteger oldLength = lengthCacheCount;
            lengthCacheCount *= 2;
            elementLengthCache = calloc(lengthCacheCount, sizeof(LengthCacheItem));
            memcpy(elementLengthCache, oldCache, oldLength * sizeof(LengthCacheItem));
            free(oldCache);
        }

        elementLengthCache[index].length = length;
        elementLengthCache[index].acceptableError = error;
    }
}

@end
