//
//  PerformanceBezierFlatTest.m
//  PerformanceBezierTests
//
//  Created by Adam Wulf on 11/18/20.
//  Copyright © 2020 Milestone Made. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PerformanceBezierAbstractTest.h"

@interface PerformanceBezierFlatTest : PerformanceBezierAbstractTest

@end

@implementation PerformanceBezierFlatTest

- (void)testSimpleFlatPath
{
    UIBezierPath *testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(0, 0)];
    [testPath addCurveToPoint:CGPointMake(100, 0) controlPoint1:CGPointMake(50, -50) controlPoint2:CGPointMake(50, 50)];

    UIBezierPath *flatPath = [testPath bezierPathByFlatteningPath];

    XCTAssertEqualWithAccuracy([flatPath length], [testPath length], 0.5);
}

- (void)testFlattenQuadratic {
    UIBezierPath *testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(100, 100)];
    [testPath addQuadCurveToPoint:CGPointMake(200, 100) controlPoint:CGPointMake(150, 250)];

    UIBezierPath *flatPath = [testPath bezierPathByFlatteningPath];

    XCTAssertEqualWithAccuracy([flatPath length], [testPath length], 0.5);
}

- (void)testFlattenQuadratic2 {
    UIBezierPath *testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(100, 100)];
    [testPath addQuadCurveToPoint:CGPointMake(200, 300) controlPoint:CGPointMake(150, 250)];

    UIBezierPath *flatPath = [testPath bezierPathByFlatteningPath];

    XCTAssertEqualWithAccuracy([flatPath length], [testPath length], 0.5);
}

- (void)testFlattenCubic {
    UIBezierPath *testPath = [UIBezierPath bezierPath];
    [testPath moveToPoint:CGPointMake(100, 100)];
    [testPath addCurveToPoint:CGPointMake(200, 200) controlPoint1:CGPointMake(150, 300) controlPoint2:CGPointMake(300, 150)];

    UIBezierPath *flatPath = [testPath bezierPathByFlatteningPath];

    XCTAssertEqualWithAccuracy([flatPath length], [testPath length], 0.5);
}

@end
