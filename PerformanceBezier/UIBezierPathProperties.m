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

@interface CacheItem: NSObject
@property (nonatomic, assign) NSTimeInterval expiration;
@property (nonatomic, weak) void(^block)(void);
@property (nonatomic, strong) dispatch_semaphore_t lock;
@end
@implementation CacheItem
- (instancetype) init {
    if (self = [super init]) {
        _lock = dispatch_semaphore_create(1);
    }
    return self;
}
- (BOOL)extend {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    if (_block) {
        _expiration = [NSDate timeIntervalSinceReferenceDate];
        dispatch_semaphore_signal(_lock);
        return YES;
    } else {
        dispatch_semaphore_signal(_lock);
        return NO;
    }
}
@end

@interface UIBezierPathPropertiesCacheHandler: NSObject
@end
@implementation UIBezierPathPropertiesCacheHandler

static NSMutableArray<CacheItem*> *cachedBlocks;

static dispatch_queue_t cacheQueue;
static const void* const kCacheQueueIdentifier = &kCacheQueueIdentifier;

+ (dispatch_queue_t)cacheQueue {
    if (!cacheQueue) {
        cacheQueue = dispatch_queue_create("com.milestonemade.cacheQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(cacheQueue, kCacheQueueIdentifier, (void*)kCacheQueueIdentifier, NULL);
    }
    return cacheQueue;
}

static CGFloat kElementCacheDuration = 5.0;
static dispatch_semaphore_t cacheSema;

+ (void)setElementCacheDuration:(CGFloat)seconds {
    kElementCacheDuration = MAX(0, seconds);
}
+ (CGFloat)elementCacheDuration{
    return kElementCacheDuration;
}

+ (void)load {
    dispatch_async([self cacheQueue], ^{
        cacheSema = dispatch_semaphore_create(1);
        cachedBlocks = [NSMutableArray array];
        [self cleanCaches];
    });
}

+ (CacheItem*)cache:(void(^)(void))block {
    CacheItem *item = [[CacheItem alloc] init];
    item.expiration = [NSDate timeIntervalSinceReferenceDate];
    item.block = block;
    dispatch_semaphore_wait(cacheSema, DISPATCH_TIME_FOREVER);
    [cachedBlocks addObject:item];
    dispatch_semaphore_signal(cacheSema);
    return item;
}

+ (void)cleanCaches {
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    for (NSInteger i=0;i<[cachedBlocks count];i++) {
        CacheItem *item = cachedBlocks[i];
        dispatch_semaphore_wait(item.lock, DISPATCH_TIME_FOREVER);
        if (item.expiration < now) {
            __strong void(^strongBlock)(void) = item.block;
            dispatch_semaphore_wait(cacheSema, DISPATCH_TIME_FOREVER);
            [cachedBlocks removeObjectAtIndex:i];
            dispatch_semaphore_signal(cacheSema);
            i -= 1;
            if (strongBlock) {
                strongBlock();
                item.block = nil;
            }
        }
        dispatch_semaphore_signal(item.lock);
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kElementCacheDuration * NSEC_PER_SEC), [self cacheQueue], ^{
        [self cleanCaches];
    });
}

@end

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

    void(^totalLengthReset)(void);
    void(^elementLengthReset)(void);
    void(^positionReset)(void);
    void(^subpathReset)(void);

    CacheItem *totalCacheItem;
    CacheItem *elementCacheItem;
    CacheItem *positionCacheItem;
    CacheItem *subpathCacheItem;
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
        [self setupCleanup];
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
    [self setupCleanup];
    return self;
}

- (void)setupCleanup {
    __weak typeof(self) weakSelf = self;
    totalLengthReset = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        @synchronized (strongSelf->lock) {
            if (strongSelf->totalLengthCacheCount > 0 && strongSelf->totalLengthCache){
                free(strongSelf->totalLengthCache);
                strongSelf->totalLengthCache = nil;
                strongSelf->totalLengthCacheCount = 0;
            }
        }
    };

    elementLengthReset = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        @synchronized (strongSelf->lock) {
            if (strongSelf->lengthCacheCount > 0 && strongSelf->elementLengthCache){
                free(strongSelf->elementLengthCache);
                strongSelf->elementLengthCache = nil;
                strongSelf->lengthCacheCount = 0;
            }
        }
    };

    positionReset = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        @synchronized (strongSelf->lock) {
            if (strongSelf->elementPositionChangeCacheCount > 0 && strongSelf->elementPositionChangeCache){
                free(strongSelf->elementPositionChangeCache);
                strongSelf->elementPositionChangeCache = nil;
                strongSelf->elementPositionChangeCacheCount = 0;
            }
        }
    };

    subpathReset = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        @synchronized (strongSelf->lock) {
            if (strongSelf->subpathRangesCount > 0 && strongSelf->subpathRanges){
                free(strongSelf->subpathRanges);
                strongSelf->subpathRanges = nil;
                strongSelf->subpathRangesCount = 0;
            }
        }
    };
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
    @synchronized (lock) {
        if (totalLengthCacheCount > 0 && totalLengthCache){
            free(totalLengthCache);
            totalLengthCache = nil;
            totalLengthCacheCount = 0;
        }
        if (lengthCacheCount > 0 && elementLengthCache){
            free(elementLengthCache);
            elementLengthCache = nil;
            lengthCacheCount = 0;
        }
        if (elementPositionChangeCacheCount > 0 && elementPositionChangeCache){
            free(elementPositionChangeCache);
            elementPositionChangeCache = nil;
            elementPositionChangeCacheCount = 0;
        }
        if (subpathRangesCount > 0 && subpathRanges){
            free(subpathRanges);
            subpathRanges = nil;
            subpathRangesCount = 0;
        }
    }

    bezierPathByFlatteningPath = nil;

    _userInfo = nil;

    lock = nil;
}

#pragma mark - Element Length Cache

- (void) resetElementLengthCache {
    if (![elementCacheItem extend]) {
        elementCacheItem = [UIBezierPathPropertiesCacheHandler cache:elementLengthReset];
    }
}

/// Returns -1 if we do not have cached information for this element that matches the input acceptableError
-(CGFloat)cachedLengthForElementIndex:(NSInteger)index acceptableError:(CGFloat)error{
    [self resetElementLengthCache];
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
    [self resetElementLengthCache];
}

#pragma mark - Total Length Cache

- (void) resetTotalLengthCache {
    if (![totalCacheItem extend]) {
        totalCacheItem = [UIBezierPathPropertiesCacheHandler cache:totalLengthReset];
    }
}

/// Returns -1 if we do not have cached information for this element that matches the input acceptableError
-(CGFloat)cachedLengthOfPathThroughElementIndex:(NSInteger)index acceptableError:(CGFloat)error {
    [self resetTotalLengthCache];
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
    [self resetTotalLengthCache];
}

#pragma mark - Cached Element Position Changes

- (void) resetPositionCache {
    if (![positionCacheItem extend]) {
        positionCacheItem = [UIBezierPathPropertiesCacheHandler cache:positionReset];
    }
}

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
    [self resetPositionCache];
}

-(ElementPositionChange)cachedElementIndexDoesChangePosition:(NSInteger)index {
    [self resetPositionCache];
    @synchronized (lock) {
        if (index < 0 || index >= elementPositionChangeCacheCount){
            return kPositionChangeUnknown;
        }

        return elementPositionChangeCache[index];
    }
}

#pragma mark - Subpath Ranges

- (void) resetSubpathCache {
    if (![subpathCacheItem extend]) {
        subpathCacheItem = [UIBezierPathPropertiesCacheHandler cache:subpathReset];
    }
}

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
    [self resetSubpathCache];
}

-(NSRange)subpathRangeForElementIndex:(NSInteger)elementIndex {
    [self resetSubpathCache];
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
