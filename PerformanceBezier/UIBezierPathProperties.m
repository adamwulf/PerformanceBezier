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
    LengthCacheItem* totalLengthCache;
    ElementPositionChange* elementPositionChangeCache;
    NSInteger lengthCacheCount;
    NSInteger totalLengthCacheCount;
    NSInteger elementPositionChangeCacheCount;
    NSObject *lock;

    NSRange *subpathRanges;
    NSInteger subpathRangesCount;
    NSInteger subpathRangesNextIndex;
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
@synthesize userInfo=_userInfo;

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)init {
    if(self = [super init]){
        elementLengthCache = nil;
        totalLengthCache = nil;
        elementPositionChangeCache = nil;
        lengthCacheCount = 0;
        totalLengthCacheCount = 0;
        elementPositionChangeCacheCount = 0;
        subpathRanges = nil;
        subpathRangesCount = 0;
        subpathRangesNextIndex = 0;
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

- (NSMutableDictionary *)userInfo {
    if (!_userInfo) {
        _userInfo = [[NSMutableDictionary alloc] init];
    }

    return _userInfo;
}

// for some reason the iPad 1 on iOS 5 needs to have this
// method coded and not synthesized.
- (void)setBezierPathByFlatteningPath:(UIBezierPath *)_bezierPathByFlatteningPath
{
    bezierPathByFlatteningPath = _bezierPathByFlatteningPath;
}

- (void)dealloc
{
    bezierPathByFlatteningPath = nil;

    _userInfo = nil;
    
    @synchronized (lock) {
        if (lengthCacheCount > 0 && elementLengthCache){
            free(elementLengthCache);
            elementLengthCache = nil;
            lengthCacheCount = 0;
        }
        if (totalLengthCacheCount > 0 && totalLengthCache){
            free(totalLengthCache);
            totalLengthCache = nil;
            totalLengthCacheCount = 0;
        }
        if (elementPositionChangeCacheCount > 0 && elementPositionChangeCache){
            free(elementPositionChangeCache);
            elementPositionChangeCache = nil;
            elementPositionChangeCacheCount = 0;
        }
        if (subpathRangesCount > 0 && subpathRanges) {
            free(subpathRanges);
            subpathRanges = nil;
            subpathRangesCount = 0;
            subpathRangesNextIndex = 0;
        }
    }

    lock = nil;
}

#pragma mark - Element Length Cache

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
            const NSInteger DefaultCount = MAX(256, pow(2, log2(index + 1) + 1));
            elementLengthCache = calloc(DefaultCount, sizeof(LengthCacheItem));
            lengthCacheCount = DefaultCount;
        } else if (index >= lengthCacheCount) {
            // increase our cache size
            LengthCacheItem* oldCache = elementLengthCache;
            NSInteger oldLength = lengthCacheCount;
            const NSInteger IdealCount = pow(2, log2(index + 1) + 1);
            lengthCacheCount = MAX(lengthCacheCount * 2, IdealCount);
            elementLengthCache = calloc(lengthCacheCount, sizeof(LengthCacheItem));
            memcpy(elementLengthCache, oldCache, oldLength * sizeof(LengthCacheItem));
            free(oldCache);
        }

        elementLengthCache[index].length = length;
        elementLengthCache[index].acceptableError = error;
    }
}

#pragma mark - Total Length Cache

/// Returns -1 if we do not have cached information for this element that matches the input acceptableError
-(CGFloat)cachedLengthOfPathThroughElementIndex:(NSInteger)index acceptableError:(CGFloat)error {
    @synchronized (lock) {
        if (index < 0 || index >= totalLengthCacheCount){
            return -1;
        }

        if (totalLengthCache[index].acceptableError == error){
            return totalLengthCache[index].length;
        }
    }

    return -1;
}

-(void)cacheLengthOfPath:(CGFloat)length throughElementIndex:(NSInteger)index acceptableError:(CGFloat)error {
    @synchronized (lock) {
        if (totalLengthCacheCount == 0){
            const NSInteger DefaultCount = MAX(256, pow(2, log2(index + 1) + 1));
            totalLengthCache = calloc(DefaultCount, sizeof(LengthCacheItem));
            totalLengthCacheCount = DefaultCount;
        } else if (index >= totalLengthCacheCount) {
            // increase our cache size
            LengthCacheItem* oldCache = totalLengthCache;
            NSInteger oldLength = totalLengthCacheCount;
            const NSInteger IdealCount = pow(2, log2(index + 1) + 1);
            totalLengthCacheCount = MAX(totalLengthCacheCount * 2, IdealCount);
            totalLengthCache = calloc(totalLengthCacheCount, sizeof(LengthCacheItem));
            memcpy(totalLengthCache, oldCache, oldLength * sizeof(LengthCacheItem));
            free(oldCache);
        }

        totalLengthCache[index].length = length;
        totalLengthCache[index].acceptableError = error;
    }
}

#pragma mark - Cached Element Position Changes

-(void)cacheElementIndex:(NSInteger)index changesPosition:(BOOL)changesPosition{
    @synchronized (lock) {
        if (elementPositionChangeCacheCount == 0){
            const NSInteger DefaultCount = MAX(256, pow(2, log2(index + 1) + 1));
            elementPositionChangeCache = calloc(DefaultCount, sizeof(ElementPositionChange));
            elementPositionChangeCacheCount = DefaultCount;
        } else if (index >= elementPositionChangeCacheCount) {
            // increase our cache size
            ElementPositionChange* oldCache = elementPositionChangeCache;
            NSInteger oldLength = elementPositionChangeCacheCount;
            const NSInteger IdealCount = pow(2, log2(index + 1) + 1);
            elementPositionChangeCacheCount = MAX(elementPositionChangeCacheCount * 2, IdealCount);
            elementPositionChangeCache = calloc(elementPositionChangeCacheCount, sizeof(ElementPositionChange));
            memcpy(elementPositionChangeCache, oldCache, oldLength * sizeof(ElementPositionChange));
            free(oldCache);
        }


        elementPositionChangeCache[index] = changesPosition ? kPositionChangeYes : kPositionChangeNo;
    }
}

-(ElementPositionChange)cachedElementIndexDoesChangePosition:(NSInteger)index {
    @synchronized (lock) {
        if (index < 0 || index >= elementPositionChangeCacheCount){
            return kPositionChangeUnknown;
        }

        return elementPositionChangeCache[index];
    }
}

#pragma mark - Subpath Ranges

// Track subpath ranges of this path. whenever an element is added to this path
// this method should be called to clear the subpath cache count
-(void)resetSubpathRangeCount {
    @synchronized (lock) {
        if (subpathRangesNextIndex > 0 && subpathRangesCount > 0) {
            subpathRangesNextIndex = 0;
        }
    }
}

-(void)cacheSubpathRange:(NSRange)range {
    @synchronized (lock) {
        if (subpathRangesCount == 0){
            const NSInteger DefaultCount = 256;
            subpathRanges = calloc(DefaultCount, sizeof(NSRange));
            subpathRangesCount = DefaultCount;
        } else if (subpathRangesNextIndex >= subpathRangesCount) {
            // increase our cache size
            NSRange* oldCache = subpathRanges;
            NSInteger oldLength = subpathRangesCount;
            const NSInteger IdealCount = pow(2, log2(subpathRangesNextIndex + 1) + 1);
            subpathRangesCount = MAX(subpathRangesCount * 2, IdealCount);
            subpathRanges = calloc(subpathRangesCount, sizeof(NSRange));
            memcpy(subpathRanges, oldCache, oldLength * sizeof(NSRange));
            free(oldCache);
        }

        subpathRanges[subpathRangesNextIndex] = range;
        subpathRangesNextIndex ++;
    }
}

-(NSRange)subpathRangeForElementIndex:(NSInteger)elementIndex {
    @synchronized (lock) {
        for (NSInteger i=0; i < subpathRangesNextIndex && i < subpathRangesCount; i++) {
            NSRange rng = subpathRanges[i];
            if (rng.length == 0) {
                break;
            }
            if (NSLocationInRange(elementIndex, rng)) {
                return rng;
            }
        }
    }
    return NSMakeRange(NSNotFound, 0);
}

@end
