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


@end
