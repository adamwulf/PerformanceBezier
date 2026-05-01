//
//  PerformanceBezierCacheGrowthTest.m
//  PerformanceBezierTests
//
//  Created by Adam Wulf on 5/1/26.
//  Copyright © 2026 Milestone Made. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PerformanceBezierAbstractTest.h"

@interface PerformanceBezierCacheGrowthTest : PerformanceBezierAbstractTest

@end

@implementation PerformanceBezierCacheGrowthTest

- (UIBezierPath *)pathWithLineSegmentCount:(NSInteger)count startingAt:(CGPoint)origin
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:origin];
    for (NSInteger i = 1; i <= count; i++) {
        [path addLineToPoint:CGPointMake(origin.x + i, origin.y)];
    }
    return path;
}

- (void)appendUnitLineSegments:(NSInteger)additionalCount toPath:(UIBezierPath *)path
{
    CGPoint last = [path lastPoint];
    for (NSInteger i = 1; i <= additionalCount; i++) {
        [path addLineToPoint:CGPointMake(last.x + i, last.y)];
    }
}

- (void)testElementLengthCacheGrowth
{
    UIBezierPath *path = [self pathWithLineSegmentCount:4 startingAt:CGPointMake(0, 0)];
    XCTAssertEqual([path elementCount], 5);

    XCTAssertEqualWithAccuracy([path lengthOfElement:1 withAcceptableError:0.5], 1.0, 0.0001);

    [self appendUnitLineSegments:195 toPath:path];
    XCTAssertEqual([path elementCount], 200);

    for (NSInteger idx = 1; idx < 200; idx++) {
        XCTAssertEqualWithAccuracy([path lengthOfElement:idx withAcceptableError:0.5], 1.0, 0.0001);
    }
}

- (void)testTotalLengthCacheGrowth
{
    UIBezierPath *path = [self pathWithLineSegmentCount:4 startingAt:CGPointMake(0, 0)];

    XCTAssertEqualWithAccuracy([path lengthOfPathThroughElement:2 withAcceptableError:0.5], 2.0, 0.0001);

    [self appendUnitLineSegments:95 toPath:path];

    XCTAssertEqualWithAccuracy([path lengthOfPathThroughElement:99 withAcceptableError:0.5], 99.0, 0.0001);
    XCTAssertEqualWithAccuracy([path lengthOfPathThroughElement:50 withAcceptableError:0.5], 50.0, 0.0001);
    XCTAssertEqualWithAccuracy([path lengthOfPathThroughElement:1 withAcceptableError:0.5], 1.0, 0.0001);
}

- (void)testChangesPositionCacheGrowth
{
    UIBezierPath *path = [self pathWithLineSegmentCount:4 startingAt:CGPointMake(0, 0)];

    XCTAssertTrue([path changesPositionDuringElement:1]);
    XCTAssertTrue([path changesPositionDuringElement:2]);

    [self appendUnitLineSegments:95 toPath:path];

    XCTAssertTrue([path changesPositionDuringElement:50]);
    XCTAssertTrue([path changesPositionDuringElement:99]);
}

- (void)testSubpathRangeCacheGrowsBeyondFloor
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    for (NSInteger s = 0; s < 30; s++) {
        [path moveToPoint:CGPointMake(s * 100, 0)];
        [path addLineToPoint:CGPointMake(s * 100 + 50, 0)];
        [path addLineToPoint:CGPointMake(s * 100 + 50, 50)];
    }

    for (NSInteger s = 0; s < 30; s++) {
        NSRange rng = [path subpathRangeForElement:s * 3];
        XCTAssertEqual(rng.location, (NSUInteger)(s * 3));
        XCTAssertEqual(rng.length, (NSUInteger)3);
    }

    NSRange first = [path subpathRangeForElement:0];
    XCTAssertEqual(first.location, (NSUInteger)0);
    XCTAssertEqual(first.length, (NSUInteger)3);

    NSRange middle = [path subpathRangeForElement:45];
    XCTAssertEqual(middle.location, (NSUInteger)45);
    XCTAssertEqual(middle.length, (NSUInteger)3);
}

// First cache write happens after the path has grown past the 16-slot floor,
// so the helper sizes the cache from cachedElementCount instead of the floor.
// Then the path grows further to force the doubling grow path off the
// exact-fit allocation.
- (void)testCacheGrowthFromKnownElementCountSizing
{
    UIBezierPath *path = [self pathWithLineSegmentCount:99 startingAt:CGPointMake(0, 0)];
    XCTAssertEqual([path elementCount], 100);

    XCTAssertEqualWithAccuracy([path lengthOfElement:50 withAcceptableError:0.5], 1.0, 0.0001);

    [self appendUnitLineSegments:200 toPath:path];
    XCTAssertEqual([path elementCount], 300);

    XCTAssertEqualWithAccuracy([path lengthOfElement:250 withAcceptableError:0.5], 1.0, 0.0001);
    XCTAssertEqualWithAccuracy([path lengthOfElement:50 withAcceptableError:0.5], 1.0, 0.0001);
    XCTAssertEqualWithAccuracy([path lengthOfElement:299 withAcceptableError:0.5], 1.0, 0.0001);
}

// After NSKeyedUnarchiver, cachedElementCount is restored but the C-array
// caches start fresh. The next length query hits Proposal B's known-count
// sizing path with a non-zero count carried in from the archive.
- (void)testCacheSizingAfterArchiverRoundTrip
{
    UIBezierPath *path = [self pathWithLineSegmentCount:50 startingAt:CGPointMake(0, 0)];
    [path lengthOfElement:25 withAcceptableError:0.5];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:path requiringSecureCoding:NO error:nil];
    UIBezierPath *restored = [NSKeyedUnarchiver unarchivedObjectOfClass:[UIBezierPath class] fromData:data error:nil];

    XCTAssertEqualWithAccuracy([restored lengthOfElement:25 withAcceptableError:0.5], 1.0, 0.0001);
    XCTAssertEqualWithAccuracy([restored lengthOfElement:0 withAcceptableError:0.5], 0.0, 0.0001);
    XCTAssertEqualWithAccuracy([restored lengthOfElement:50 withAcceptableError:0.5], 1.0, 0.0001);
}

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

// Mutating the copy (including a removeAllPoints+rebuild that frees and
// reallocates the copy's own caches) must not corrupt the original's caches.
- (void)testCopiedPathHasIndependentCaches
{
    UIBezierPath *original = [self pathWithLineSegmentCount:4 startingAt:CGPointMake(0, 0)];
    [original lengthOfElement:1 withAcceptableError:0.5];

    UIBezierPath *copy = [original copy];

    [copy removeAllPoints];
    [copy moveToPoint:CGPointMake(0, 0)];
    for (NSInteger i = 1; i <= 100; i++) {
        [copy addLineToPoint:CGPointMake(i * 5, 0)];
    }
    [copy lengthOfElement:50 withAcceptableError:0.5];
    [copy lengthOfElement:99 withAcceptableError:0.5];

    XCTAssertEqual([original elementCount], 5);
    XCTAssertEqualWithAccuracy([original lengthOfElement:1 withAcceptableError:0.5], 1.0, 0.0001);
    XCTAssertEqualWithAccuracy([original lengthOfElement:4 withAcceptableError:0.5], 1.0, 0.0001);
}

// Sanity check that calloc/free pairs balance under high path churn.
// Run under the leaks/asan instruments to catch regressions.
- (void)testManySmallPathsAllocateAndFreeCleanly
{
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

@end
