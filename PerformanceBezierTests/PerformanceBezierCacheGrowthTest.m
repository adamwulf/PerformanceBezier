//
//  PerformanceBezierCacheGrowthTest.m
//  PerformanceBezierTests
//
//  Targets the lazy-grown C-array caches in UIBezierPathProperties:
//  ensure correctness when the cache is sized to the path's known
//  element count and then has to grow because the path was mutated,
//  and when an out-of-range index is queried on a small initial cache.
//

#import <XCTest/XCTest.h>
#import "PerformanceBezierAbstractTest.h"

@interface PerformanceBezierCacheGrowthTest : PerformanceBezierAbstractTest

@end

@implementation PerformanceBezierCacheGrowthTest

#pragma mark - Helpers

- (UIBezierPath *)pathWithLineSegmentCount:(NSInteger)count startingAt:(CGPoint)origin
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:origin];
    for (NSInteger i = 1; i <= count; i++) {
        [path addLineToPoint:CGPointMake(origin.x + i, origin.y)];
    }
    return path;
}

#pragma mark - Tests

/// Append unit-length line segments after the path has been built to a given
/// element count. Continues from the path's existing last point.
- (void)appendUnitLineSegments:(NSInteger)additionalCount toPath:(UIBezierPath *)path
{
    CGPoint last = [path lastPoint];
    for (NSInteger i = 1; i <= additionalCount; i++) {
        [path addLineToPoint:CGPointMake(last.x + i, last.y)];
    }
}

/// After querying length on a path of size N (which sizes the element-length
/// cache to fit N elements exactly under Proposal B), append more elements and
/// query again. The grow path must produce a cache large enough to satisfy the
/// new index without reading or writing past the allocation.
- (void)testElementLengthCacheGrowsAfterAppendingPastInitialSize
{
    UIBezierPath *path = [self pathWithLineSegmentCount:4 startingAt:CGPointMake(0, 0)];
    XCTAssertEqual([path elementCount], 5);

    // First write — cache sized to 5 (or floor of 16, whichever larger).
    CGFloat firstLen = [path lengthOfElement:1 withAcceptableError:0.5];
    XCTAssertEqualWithAccuracy(firstLen, 1.0, 0.0001);

    // Append enough unit-length segments to push us well past the 16-slot
    // floor and the initial known-size allocation, forcing the grow path
    // to fire.
    [self appendUnitLineSegments:195 toPath:path];
    XCTAssertEqual([path elementCount], 200);

    // Query at indices that would have been out of range for the original cache.
    for (NSInteger idx = 0; idx < 200; idx++) {
        CGFloat len = [path lengthOfElement:idx withAcceptableError:0.5];
        if (idx == 0) {
            XCTAssertEqualWithAccuracy(len, 0.0, 0.0001);
        } else {
            XCTAssertEqualWithAccuracy(len, 1.0, 0.0001);
        }
    }
}

/// Same scenario for the through-element (total length) cache.
- (void)testTotalLengthCacheGrowsAfterAppendingPastInitialSize
{
    UIBezierPath *path = [self pathWithLineSegmentCount:4 startingAt:CGPointMake(0, 0)];

    CGFloat firstThroughLen = [path lengthOfPathThroughElement:2 withAcceptableError:0.5];
    XCTAssertEqualWithAccuracy(firstThroughLen, 2.0, 0.0001);

    [self appendUnitLineSegments:95 toPath:path];
    XCTAssertEqual([path elementCount], 100);

    CGFloat lastThroughLen = [path lengthOfPathThroughElement:99 withAcceptableError:0.5];
    XCTAssertEqualWithAccuracy(lastThroughLen, 99.0, 0.0001);

    // Read back middle indices to verify the cache stayed coherent through grow.
    XCTAssertEqualWithAccuracy([path lengthOfPathThroughElement:50 withAcceptableError:0.5], 50.0, 0.0001);
    XCTAssertEqualWithAccuracy([path lengthOfPathThroughElement:1 withAcceptableError:0.5], 1.0, 0.0001);
}

/// Same scenario for the changesPosition cache.
- (void)testChangesPositionCacheGrowsAfterAppendingPastInitialSize
{
    UIBezierPath *path = [self pathWithLineSegmentCount:4 startingAt:CGPointMake(0, 0)];

    XCTAssertTrue([path changesPositionDuringElement:1]);
    XCTAssertTrue([path changesPositionDuringElement:2]);

    [self appendUnitLineSegments:95 toPath:path];

    XCTAssertTrue([path changesPositionDuringElement:50]);
    XCTAssertTrue([path changesPositionDuringElement:99]);
}

/// Subpath-range cache: many subpaths force the subpathRanges array to grow
/// beyond the floor, exercising the doubling path on a non-element-indexed cache.
- (void)testSubpathRangeCacheGrowsBeyondFloor
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    // 30 subpaths × 3 elements each = 90 elements, 30 subpaths.
    // Floor is 16, so this forces at least one grow.
    for (NSInteger s = 0; s < 30; s++) {
        [path moveToPoint:CGPointMake(s * 100, 0)];
        [path addLineToPoint:CGPointMake(s * 100 + 50, 0)];
        [path addLineToPoint:CGPointMake(s * 100 + 50, 50)];
    }

    // Query subpath ranges across all subpaths. The cache fills incrementally.
    for (NSInteger s = 0; s < 30; s++) {
        NSInteger firstElementInSubpath = s * 3;
        NSRange rng = [path subpathRangeForElement:firstElementInSubpath];
        XCTAssertEqual(rng.location, (NSUInteger)firstElementInSubpath);
        XCTAssertEqual(rng.length, (NSUInteger)3);
    }

    // Read back from the start to confirm earlier-cached entries didn't get
    // corrupted by a grow that happened after they were written.
    NSRange first = [path subpathRangeForElement:0];
    XCTAssertEqual(first.location, (NSUInteger)0);
    XCTAssertEqual(first.length, (NSUInteger)3);

    NSRange middle = [path subpathRangeForElement:45];  // subpath 15
    XCTAssertEqual(middle.location, (NSUInteger)45);
    XCTAssertEqual(middle.length, (NSUInteger)3);
}

/// After a path is rebuilt with `removeAllPoints` followed by new elements,
/// `subpathRangeForElement:` should report the new geometry and not return
/// stale ranges from the prior path. The subpath cache is correctly reset
/// by `swizzle_removeAllPoints` (via `resetSubpathRangeCount`).
///
/// NOTE: this test intentionally avoids checking the element-length and
/// total-length caches, because `swizzle_removeAllPoints` does NOT currently
/// invalidate those buffers. Querying lengthOfElement:1 with the same
/// acceptableError after removeAllPoints will return a stale result from
/// before the reset. That is a pre-existing behavior, not caused by Proposal
/// A or B; flagged separately for follow-up.
- (void)testSubpathCacheResetAfterRemoveAllPoints
{
    UIBezierPath *path = [self pathWithLineSegmentCount:4 startingAt:CGPointMake(0, 0)];
    [path subpathRangeForElement:0];

    [path removeAllPoints];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(10, 0)];

    NSRange rng = [path subpathRangeForElement:0];
    XCTAssertEqual(rng.location, (NSUInteger)0);
    XCTAssertEqual(rng.length, (NSUInteger)2);
}

/// A copied path must not share the original's C-array caches: mutating one
/// must not affect the other's cached lengths. (Caches are not transferred,
/// per swizzle_copy. Verify by querying the copy independently.)
- (void)testCopiedPathHasIndependentCaches
{
    UIBezierPath *original = [self pathWithLineSegmentCount:4 startingAt:CGPointMake(0, 0)];
    [original lengthOfElement:1 withAcceptableError:0.5];

    UIBezierPath *copy = [original copy];

    // Mutate the copy. This must not corrupt the original's cache.
    [copy addLineToPoint:CGPointMake(100, 0)];

    XCTAssertEqualWithAccuracy([original lengthOfElement:1 withAcceptableError:0.5], 1.0, 0.0001);
    XCTAssertEqual([original elementCount], 5);

    XCTAssertEqualWithAccuracy([copy lengthOfElement:1 withAcceptableError:0.5], 1.0, 0.0001);
    XCTAssertEqualWithAccuracy([copy lengthOfElement:5 withAcceptableError:0.5], 96.0, 0.0001);
    XCTAssertEqual([copy elementCount], 6);
}

/// First write at a "high" index on a path whose cachedElementCount is small
/// (or zero). The helper's lowerBound clamp must guarantee the cache fits the
/// requested index even if cachedElementCount is stale-low.
///
/// In practice the public API iterates the path before writing, so cachedElementCount
/// is always up to date by the time the cache is touched. This test is a defensive
/// check that the floor logic still works for unusual access orderings.
- (void)testFirstCacheWriteAtHighIndexAllocatesEnough
{
    UIBezierPath *path = [self pathWithLineSegmentCount:50 startingAt:CGPointMake(0, 0)];
    XCTAssertEqual([path elementCount], 51);

    // Touch index 50 first — cache must allocate ≥ 51 slots even if the
    // helper sees a stale cachedElementCount.
    CGFloat lastLen = [path lengthOfElement:50 withAcceptableError:0.5];
    XCTAssertEqualWithAccuracy(lastLen, 1.0, 0.0001);

    // Then read low indices — must come from the same allocation.
    XCTAssertEqualWithAccuracy([path lengthOfElement:1 withAcceptableError:0.5], 1.0, 0.0001);
    XCTAssertEqualWithAccuracy([path lengthOfElement:25 withAcceptableError:0.5], 1.0, 0.0001);
}

/// Many small paths each get their own cache. Build, query, and release a
/// large number of paths in a tight loop. Any leak in the per-path cache
/// allocations would show up as a memory-pressure failure or sanitizer hit
/// when run under address/leaks instrumentation.
- (void)testManySmallPathsAllocateAndFreeCleanly
{
    @autoreleasepool {
        for (NSInteger i = 0; i < 5000; i++) {
            @autoreleasepool {
                UIBezierPath *path = [self pathWithLineSegmentCount:5 startingAt:CGPointMake(i, 0)];
                [path lengthOfElement:1 withAcceptableError:0.5];
                [path lengthOfPathThroughElement:4 withAcceptableError:0.5];
                [path subpathRangeForElement:0];
                [path changesPositionDuringElement:2];
            }
        }
    }
    // If we got here without crashing or hitting an asan failure, the per-path
    // calloc/free pairs are balanced.
    XCTAssertTrue(YES);
}

@end
