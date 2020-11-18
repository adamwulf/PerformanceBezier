//
//  PerformanceBezierElementTest.m
//  PerformanceBezierTests
//
//  Created by Adam Wulf on 5/21/20.
//  Copyright © 2020 Milestone Made. All rights reserved.
//

#import "PerformanceBezierAbstractTest.h"

@interface PerformanceBezierElementTest : PerformanceBezierAbstractTest

@end

@implementation PerformanceBezierElementTest

- (void)testStartTangent {
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [simplePath moveToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 99)];

    CGPoint tangent = [simplePath tangentOnPathAtElement:1 andTValue:0];
    
    XCTAssertEqual(tangent.x, 1);
    XCTAssertEqual(tangent.y, 0);

    tangent = [simplePath tangentOnPathAtElement:0 andTValue:0];

    XCTAssertEqual(tangent.x, 1);
    XCTAssertEqual(tangent.y, 0);

    tangent = [simplePath tangentOnPathAtElement:0 andTValue:1];

    XCTAssertEqual(tangent.x, 1);
    XCTAssertEqual(tangent.y, 0);

    tangent = [simplePath tangentOnPathAtElement:0 andTValue:.5];

    XCTAssertEqual(tangent.x, 1);
    XCTAssertEqual(tangent.y, 0);
}

- (void)testEndTangent {
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [simplePath moveToPoint:CGPointMake(0, 0)];
    [simplePath addLineToPoint:CGPointMake(100, 0)];
    [simplePath addLineToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(0, 100)];
    [simplePath closePath];

    CGPoint tangent = [simplePath tangentOnPathAtElement:4 andTValue:0];

    XCTAssertEqual(tangent.x, 0);
    XCTAssertEqual(tangent.y, -1);

    tangent = [simplePath tangentOnPathAtElement:4 andTValue:1];

    XCTAssertEqual(tangent.x, 0);
    XCTAssertEqual(tangent.y, -1);
}

- (void)testEndTangent2 {
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [simplePath moveToPoint:CGPointMake(0, 0)];
    [simplePath addLineToPoint:CGPointMake(100, 0)];
    [simplePath addLineToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(0, 100)];
    [simplePath addLineToPoint:CGPointMake(0, 0)];
    [simplePath closePath];

    CGPoint tangent = [simplePath tangentOnPathAtElement:5 andTValue:0];

    XCTAssertEqual(tangent.x, 0);
    XCTAssertEqual(tangent.y, -1);

    tangent = [simplePath tangentOnPathAtElement:5 andTValue:1];

    XCTAssertEqual(tangent.x, 0);
    XCTAssertEqual(tangent.y, -1);

    tangent = [simplePath tangentOnPathAtElement:4 andTValue:1];

    XCTAssertEqual(tangent.x, 0);
    XCTAssertEqual(tangent.y, -1);
}

- (void)testCornerTangent {
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [simplePath moveToPoint:CGPointMake(0, 0)];
    [simplePath addLineToPoint:CGPointMake(100, 0)];
    [simplePath addLineToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(0, 100)];
    [simplePath addLineToPoint:CGPointMake(0, 0)];
    [simplePath closePath];

    CGPoint tangent = [simplePath tangentOnPathAtElement:1 andTValue:1];

    XCTAssertEqual(tangent.x, 1);
    XCTAssertEqual(tangent.y, 0);

    tangent = [simplePath tangentOnPathAtElement:2 andTValue:0];

    XCTAssertEqual(tangent.x, 0);
    XCTAssertEqual(tangent.y, 1);
}

- (void)testElementLength {
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [simplePath moveToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 99)];

    CGFloat len = [simplePath lengthOfElement:1 withAcceptableError:kIntersectionPointPrecision];
    
    XCTAssertEqual(len, 100);
    
    simplePath = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:simplePath]];
    
    len = [simplePath lengthOfElement:1 withAcceptableError:kIntersectionPointPrecision];
    
    XCTAssertEqual(len, 100);
}

- (void)testLengthThroughElement {
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [simplePath moveToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 99)];

    CGFloat len = [simplePath lengthOfPathThroughElement:0 withAcceptableError:kIntersectionPointPrecision];

    XCTAssertEqual(len, 0);

    len = [simplePath lengthOfPathThroughElement:1 withAcceptableError:kIntersectionPointPrecision];

    XCTAssertEqual(len, 100);

    len = [simplePath lengthOfPathThroughElement:2 withAcceptableError:kIntersectionPointPrecision];

    XCTAssertEqual(len, 101);

    simplePath = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:simplePath]];

    len = [simplePath lengthOfPathThroughElement:0 withAcceptableError:kIntersectionPointPrecision];

    XCTAssertEqual(len, 0);

    len = [simplePath lengthOfPathThroughElement:1 withAcceptableError:kIntersectionPointPrecision];

    XCTAssertEqual(len, 100);

    len = [simplePath lengthOfPathThroughElement:2 withAcceptableError:kIntersectionPointPrecision];

    XCTAssertEqual(len, 101);
}

/// Tests same as above, ensuring recursion will calculate correctly
- (void)testLengthThroughElement2 {
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [simplePath moveToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 99)];

    CGFloat len = [simplePath lengthOfPathThroughElement:2 withAcceptableError:kIntersectionPointPrecision];

    XCTAssertEqual(len, 101);

    len = [simplePath lengthOfPathThroughElement:1 withAcceptableError:kIntersectionPointPrecision];

    XCTAssertEqual(len, 100);
}

- (void)testLengthThroughElement3 {
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [simplePath moveToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 99)];

    CGFloat len = [simplePath lengthOfPathThroughElement:1 tValue:.75 withAcceptableError:kIntersectionPointPrecision];

    XCTAssertEqual(len, 75);

    len = [simplePath lengthOfPathThroughElement:2 tValue:.75 withAcceptableError:kIntersectionPointPrecision];

    XCTAssertEqual(len, 100.75);
}

- (void)testLengthThroughElement4 {
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [simplePath moveToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 100)];
    [simplePath addLineToPoint:CGPointMake(199, 100)];
    [simplePath closePath];

    CGFloat len = [simplePath lengthOfPathThroughElement:1 tValue:.75 withAcceptableError:kIntersectionPointPrecision];

    XCTAssertEqual(len, 75);

    len = [simplePath lengthOfPathThroughElement:2 tValue:.75 withAcceptableError:kIntersectionPointPrecision];

    XCTAssertEqual(len, 100.75);

    len = [simplePath lengthOfPathThroughElement:3 tValue:0.5 withAcceptableError:kIntersectionPointPrecision];

    XCTAssertEqual(len, 150.5);
}

/// Tests same as above, ensuring recursion will calculate correctly
- (void)testMultipleSubpaths {
    UIBezierPath *path;
    path = [UIBezierPath bezierPathWithRect:CGRectMake(100, 100, 600, 400)];
    [path appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(150, 150, 200, 200)] bezierPathByReversingPath]];

    CGFloat len = [path lengthOfPathThroughElement:2 withAcceptableError:kIntersectionPointPrecision];

    XCTAssertEqual(len, 1000);

    len = [path lengthOfPathThroughElement:1 withAcceptableError:kIntersectionPointPrecision];

    XCTAssertEqual(len, 600);

    len = [path length];

    XCTAssertEqual(len, 2800);

    // read from cache
    len = [path length];

    XCTAssertEqual(len, 2800);
}

/// Tests same as above, ensuring recursion will calculate correctly
- (void)testEmptyPathLength {
    UIBezierPath *path = [UIBezierPath bezierPath];

    CGFloat len = [path length];

    XCTAssertEqual(len, 0);
}

- (void)testSubpathRangeForIndexClosePath
{
    NSRange key = NSMakeRange(0, 4);
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(0, 100)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path closePath];

    NSRange rng = [path subpathRangeForElement:0];

    XCTAssertEqual(rng.location, key.location);
    XCTAssertEqual(rng.length, key.length);

    rng = [path subpathRangeForElement:1];

    XCTAssertEqual(rng.location, key.location);
    XCTAssertEqual(rng.length, key.length);

    rng = [path subpathRangeForElement:2];

    XCTAssertEqual(rng.location, key.location);
    XCTAssertEqual(rng.length, key.length);

    rng = [path subpathRangeForElement:3];

    XCTAssertEqual(rng.location, key.location);
    XCTAssertEqual(rng.length, key.length);
}

- (void)testSubpathRangeForIndexOpenPath
{
    NSRange key = NSMakeRange(0, 3);
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(0, 100)];
    [path addLineToPoint:CGPointMake(100, 0)];

    NSRange rng = [path subpathRangeForElement:0];

    XCTAssertEqual(rng.location, key.location);
    XCTAssertEqual(rng.length, key.length);

    rng = [path subpathRangeForElement:1];

    XCTAssertEqual(rng.location, key.location);
    XCTAssertEqual(rng.length, key.length);

    rng = [path subpathRangeForElement:2];

    XCTAssertEqual(rng.location, key.location);
    XCTAssertEqual(rng.length, key.length);
}

- (void)testSubpathRangeForIndexMultiplePaths
{
    NSRange key1 = NSMakeRange(0, 3);
    NSRange key2 = NSMakeRange(3, 3);
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(0, 100)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(0, 100)];
    [path addLineToPoint:CGPointMake(100, 0)];

    NSRange rng = [path subpathRangeForElement:0];

    XCTAssertEqual(rng.location, key1.location);
    XCTAssertEqual(rng.length, key1.length);

    rng = [path subpathRangeForElement:1];

    XCTAssertEqual(rng.location, key1.location);
    XCTAssertEqual(rng.length, key1.length);

    rng = [path subpathRangeForElement:2];

    XCTAssertEqual(rng.location, key1.location);
    XCTAssertEqual(rng.length, key1.length);

    rng = [path subpathRangeForElement:3];

    XCTAssertEqual(rng.location, key2.location);
    XCTAssertEqual(rng.length, key2.length);

    rng = [path subpathRangeForElement:4];

    XCTAssertEqual(rng.location, key2.location);
    XCTAssertEqual(rng.length, key2.length);

    rng = [path subpathRangeForElement:5];

    XCTAssertEqual(rng.location, key2.location);
    XCTAssertEqual(rng.length, key2.length);
}

- (void)testSubpathRangeForIndexAdjacentMoveTo
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path moveToPoint:CGPointMake(0, 0)];
    [path moveToPoint:CGPointMake(0, 0)];

    NSRange rng = [path subpathRangeForElement:0];

    XCTAssertEqual(rng.location, 0);
    XCTAssertEqual(rng.length, 1);

    rng = [path subpathRangeForElement:1];

    XCTAssertEqual(rng.location, 1);
    XCTAssertEqual(rng.length, 1);

    rng = [path subpathRangeForElement:2];

    XCTAssertEqual(rng.location, 2);
    XCTAssertEqual(rng.length, 1);
}

- (void)testSubpathRangeForIndexTinyPaths
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path closePath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path closePath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path closePath];

    NSRange rng = [path subpathRangeForElement:0];

    XCTAssertEqual(rng.location, 0);
    XCTAssertEqual(rng.length, 2);

    rng = [path subpathRangeForElement:1];

    XCTAssertEqual(rng.location, 0);
    XCTAssertEqual(rng.length, 2);

    rng = [path subpathRangeForElement:2];

    XCTAssertEqual(rng.location, 2);
    XCTAssertEqual(rng.length, 2);

    rng = [path subpathRangeForElement:3];

    XCTAssertEqual(rng.location, 2);
    XCTAssertEqual(rng.length, 2);

    rng = [path subpathRangeForElement:4];

    XCTAssertEqual(rng.location, 4);
    XCTAssertEqual(rng.length, 2);

    rng = [path subpathRangeForElement:5];

    XCTAssertEqual(rng.location, 4);
    XCTAssertEqual(rng.length, 2);
}

- (void)testSubpathChangesDuring
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path closePath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path closePath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path closePath];

    XCTAssertFalse([path changesPositionDuringElement:0]);
    XCTAssertFalse([path changesPositionDuringElement:1]);
    XCTAssertFalse([path changesPositionDuringElement:2]);
    XCTAssertFalse([path changesPositionDuringElement:3]);
    XCTAssertFalse([path changesPositionDuringElement:4]);
    XCTAssertFalse([path changesPositionDuringElement:5]);
}

- (void)testSubpathChangesDuring2
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path closePath];
    [path moveToPoint:CGPointMake(100, 0)];
    [path closePath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path closePath];

    XCTAssertFalse([path changesPositionDuringElement:0]);
    XCTAssertTrue([path changesPositionDuringElement:1]);
    XCTAssertTrue([path changesPositionDuringElement:2]);
    XCTAssertFalse([path changesPositionDuringElement:3]);
    XCTAssertFalse([path changesPositionDuringElement:4]);
    XCTAssertFalse([path changesPositionDuringElement:5]);
}

- (void)testSubpathChangesDuring3
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addLineToPoint:CGPointMake(0, 0)];
    [path closePath];

    XCTAssertFalse([path changesPositionDuringElement:0]);
    XCTAssertTrue([path changesPositionDuringElement:1]);
    XCTAssertTrue([path changesPositionDuringElement:2]);
    XCTAssertFalse([path changesPositionDuringElement:3]);
}

- (void)testSubpathChangesDuring4
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addLineToPoint:CGPointMake(0, 0)];
    [path closePath];

    XCTAssertFalse([path changesPositionDuringElement:0]);
    XCTAssertTrue([path changesPositionDuringElement:1]);
    XCTAssertFalse([path changesPositionDuringElement:2]);
    XCTAssertFalse([path changesPositionDuringElement:3]);
    XCTAssertFalse([path changesPositionDuringElement:4]);
    XCTAssertFalse([path changesPositionDuringElement:5]);
    XCTAssertTrue([path changesPositionDuringElement:6]);
    XCTAssertFalse([path changesPositionDuringElement:7]);
}

- (void)testSubpathChangesDuring5
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path closePath];

    XCTAssertFalse([path changesPositionDuringElement:0]);
    XCTAssertTrue([path changesPositionDuringElement:1]);
    XCTAssertFalse([path changesPositionDuringElement:2]);
    XCTAssertFalse([path changesPositionDuringElement:3]);
    XCTAssertFalse([path changesPositionDuringElement:4]);
    XCTAssertFalse([path changesPositionDuringElement:5]);
    XCTAssertTrue([path changesPositionDuringElement:6]);
}

- (void)testSubpathChangesDuring6
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addQuadCurveToPoint:CGPointMake(100, 0) controlPoint:CGPointMake(100, 0)];
    [path addQuadCurveToPoint:CGPointMake(200, 0) controlPoint:CGPointMake(100, 0)];
    [path addQuadCurveToPoint:CGPointMake(100, 0) controlPoint:CGPointMake(100, 0)];
    [path addQuadCurveToPoint:CGPointMake(100, 0) controlPoint:CGPointMake(200, 0)];
    [path addQuadCurveToPoint:CGPointMake(100, 0) controlPoint:CGPointMake(100, 0)];
    [path closePath];

    XCTAssertFalse([path changesPositionDuringElement:0]);
    XCTAssertTrue([path changesPositionDuringElement:1]);
    XCTAssertFalse([path changesPositionDuringElement:2]);
    XCTAssertTrue([path changesPositionDuringElement:3]);
    XCTAssertTrue([path changesPositionDuringElement:4]);
    XCTAssertTrue([path changesPositionDuringElement:5]);
    XCTAssertFalse([path changesPositionDuringElement:6]);
    XCTAssertTrue([path changesPositionDuringElement:7]);
}

- (void)testSubpathChangesDuring7
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addCurveToPoint:CGPointMake(100, 0) controlPoint1:CGPointMake(100, 0) controlPoint2:CGPointMake(100, 0)];
    [path addCurveToPoint:CGPointMake(200, 0) controlPoint1:CGPointMake(100, 0) controlPoint2:CGPointMake(100, 0)];
    [path addCurveToPoint:CGPointMake(100, 0) controlPoint1:CGPointMake(100, 0) controlPoint2:CGPointMake(100, 0)];
    [path addCurveToPoint:CGPointMake(100, 0) controlPoint1:CGPointMake(200, 0) controlPoint2:CGPointMake(100, 0)];
    [path addCurveToPoint:CGPointMake(100, 0) controlPoint1:CGPointMake(100, 0) controlPoint2:CGPointMake(100, 0)];
    [path addCurveToPoint:CGPointMake(100, 0) controlPoint1:CGPointMake(100, 0) controlPoint2:CGPointMake(200, 0)];
    [path closePath];

    XCTAssertFalse([path changesPositionDuringElement:0]);
    XCTAssertTrue([path changesPositionDuringElement:1]);
    XCTAssertFalse([path changesPositionDuringElement:2]);
    XCTAssertTrue([path changesPositionDuringElement:3]);
    XCTAssertTrue([path changesPositionDuringElement:4]);
    XCTAssertTrue([path changesPositionDuringElement:5]);
    XCTAssertFalse([path changesPositionDuringElement:6]);
    XCTAssertTrue([path changesPositionDuringElement:7]);
    XCTAssertTrue([path changesPositionDuringElement:8]);
}

- (void)testTValueLoopBackwardClose
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(400, 300)];
    [path addLineToPoint:CGPointMake(300, 400)];
    [path addLineToPoint:CGPointMake(200, 300)];
    [path addLineToPoint:CGPointMake(300, 200)];
    [path addLineToPoint:CGPointMake(400, 300)];
    [path closePath];

    XCTAssertFalse([path changesPositionDuringElement:0]);
    XCTAssertTrue([path changesPositionDuringElement:1]);
    XCTAssertTrue([path changesPositionDuringElement:2]);
    XCTAssertTrue([path changesPositionDuringElement:3]);
    XCTAssertTrue([path changesPositionDuringElement:4]);
    XCTAssertFalse([path changesPositionDuringElement:5]);
}

- (void)testTValueClippingCase
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(400, 300)];
    [path addCurveToPoint:CGPointMake(300, 400) controlPoint1:CGPointMake(400, 355.22847498) controlPoint2:CGPointMake(355.22847498, 400)];
    [path addCurveToPoint:CGPointMake(200, 300) controlPoint1:CGPointMake(244.77152502, 400) controlPoint2:CGPointMake(200, 355.22847498)];
    [path addCurveToPoint:CGPointMake(300, 200) controlPoint1:CGPointMake(200, 244.77152502) controlPoint2:CGPointMake(244.77152502, 200)];
    [path addCurveToPoint:CGPointMake(400, 300) controlPoint1:CGPointMake(355.22847498, 200) controlPoint2:CGPointMake(400, 244.77152502)];
    [path closePath];

    XCTAssertFalse([path changesPositionDuringElement:0]);
    XCTAssertTrue([path changesPositionDuringElement:1]);
    XCTAssertTrue([path changesPositionDuringElement:2]);
    XCTAssertTrue([path changesPositionDuringElement:3]);
    XCTAssertTrue([path changesPositionDuringElement:4]);
    XCTAssertFalse([path changesPositionDuringElement:5]);
}

- (void)testTValueLoopBackwardClose2
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(400, 300)];
    [path addLineToPoint:CGPointMake(300, 400)];
    [path addLineToPoint:CGPointMake(200, 300)];
    [path addLineToPoint:CGPointMake(300, 200)];
    [path closePath];

    XCTAssertFalse([path changesPositionDuringElement:0]);
    XCTAssertTrue([path changesPositionDuringElement:1]);
    XCTAssertTrue([path changesPositionDuringElement:2]);
    XCTAssertTrue([path changesPositionDuringElement:3]);
    XCTAssertTrue([path changesPositionDuringElement:4]);
}

- (void)testTValueClippingCase2
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(400, 300)];
    [path addCurveToPoint:CGPointMake(300, 400) controlPoint1:CGPointMake(400, 355.22847498) controlPoint2:CGPointMake(355.22847498, 400)];
    [path addCurveToPoint:CGPointMake(200, 300) controlPoint1:CGPointMake(244.77152502, 400) controlPoint2:CGPointMake(200, 355.22847498)];
    [path addCurveToPoint:CGPointMake(300, 200) controlPoint1:CGPointMake(200, 244.77152502) controlPoint2:CGPointMake(244.77152502, 200)];
    [path closePath];

    XCTAssertFalse([path changesPositionDuringElement:0]);
    XCTAssertTrue([path changesPositionDuringElement:1]);
    XCTAssertTrue([path changesPositionDuringElement:2]);
    XCTAssertTrue([path changesPositionDuringElement:3]);
    XCTAssertTrue([path changesPositionDuringElement:4]);
}

@end
