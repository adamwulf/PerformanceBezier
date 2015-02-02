//
//  DrawKitiOSClockwiseTests.m
//  DrawKit-iOS
//
//  Created by Adam Wulf on 1/7/14.
//  Copyright (c) 2014 Milestone Made, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PerformanceBezierAbstractTest.h"

@interface PerformanceBezierClockwiseTests : PerformanceBezierAbstractTest

@end

@implementation PerformanceBezierClockwiseTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testLinearCounterClockwise
{
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [simplePath moveToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 99)];
    
    XCTAssertTrue(![simplePath isClockwise], @"clockwise is correct");
}

- (void)testLinearClockwise
{
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [simplePath moveToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 101)];
    
    XCTAssertTrue(![simplePath isClockwise], @"clockwise is correct");
}

- (void)testLinearEmptyShape
{
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [simplePath moveToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 101)];
    [simplePath closePath];
    
    XCTAssertTrue([simplePath isClockwise], @"clockwise is correct");
}

- (void)testLinearEmptyShape2
{
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [simplePath moveToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 99)];
    [simplePath closePath];
    
    XCTAssertTrue(![simplePath isClockwise], @"clockwise is correct");
}

- (void)testSimpleClockwiseCurve
{
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [simplePath moveToPoint:CGPointMake(100, 100)];
    [simplePath addCurveToPoint:CGPointMake(200, 100) controlPoint1:CGPointMake(100, 0) controlPoint2:CGPointMake(200, 0)];
    
    XCTAssertTrue([simplePath isClockwise], @"clockwise is correct");
}

- (void)testSimpleCounterClockwiseCurve
{
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [simplePath moveToPoint:CGPointMake(100, 100)];
    [simplePath addCurveToPoint:CGPointMake(200, 100) controlPoint1:CGPointMake(100, 200) controlPoint2:CGPointMake(200, 200)];
    
    XCTAssertTrue(![simplePath isClockwise], @"clockwise is correct");
}

- (void)testSimplePath
{
    UIBezierPath* simplePath = [UIBezierPath bezierPathWithArcCenter:CGPointZero radius:10 startAngle:0 endAngle:M_PI clockwise:YES];
    
    XCTAssertTrue([simplePath isClockwise], @"clockwise is correct");
}

- (void)testSimplePath2
{
    UIBezierPath* simplePath = [UIBezierPath bezierPathWithArcCenter:CGPointZero radius:10 startAngle:0 endAngle:M_PI clockwise:NO];
    
    XCTAssertTrue(![simplePath isClockwise], @"clockwise is correct");
}

- (void)testComplexPath
{
    XCTAssertTrue([self.complexShape isClockwise], @"clockwise is correct");
}

- (void)testReversedComplexPath
{
    XCTAssertTrue(![[self.complexShape bezierPathByReversingPath] isClockwise], @"clockwise is correct");
}


@end
