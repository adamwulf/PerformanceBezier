//
//  PerformanceBezierTrimTest.m
//  PerformanceBezierTests
//
//  Created by Adam Wulf on 5/14/20.
//  Copyright © 2020 Milestone Made. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PerformanceBezierAbstractTest.h"

@interface PerformanceBezierTrimTest : PerformanceBezierAbstractTest

@end

@implementation PerformanceBezierTrimTest

- (void)testTrimFromElement
{
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [simplePath setLineWidth:10];
    [simplePath moveToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 99)];

    UIBezierPath* trimmedPath = [UIBezierPath bezierPath];
    [trimmedPath setLineWidth:10];
    [trimmedPath moveToPoint:CGPointMake(200, 100)];
    [trimmedPath addLineToPoint:CGPointMake(200, 99)];

    XCTAssertEqualObjects([simplePath bezierPathByTrimmingFromElement:2], trimmedPath);
}

- (void)testTrimClosedElement
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addLineToPoint:CGPointMake(-100, 50)];
    [path addLineToPoint:CGPointMake(100, 100)];
    [path addLineToPoint:CGPointMake(0, 100)];
    [path closePath];

    UIBezierPath *slice = [path bezierPathByTrimmingFromElement:5 andTValue:0.75];

    UIBezierPath *key = [UIBezierPath bezierPath];
    [key moveToPoint:CGPointMake(0, 25)];
    [key addLineToPoint:CGPointMake(0, 0)];

    XCTAssert([slice isEqualToBezierPath:key withAccuracy:0.00001]);
}

- (void)testTrimClosedElement2
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(100, 0)];
    [path addLineToPoint:CGPointMake(-100, 50)];
    [path addLineToPoint:CGPointMake(100, 100)];
    [path addLineToPoint:CGPointMake(0, 100)];
    [path closePath];

    UIBezierPath *slice = [path bezierPathByTrimmingToElement:5 andTValue:0.75];

    UIBezierPath *key = [UIBezierPath bezierPath];
    [key moveToPoint:CGPointMake(0, 0)];
    [key addLineToPoint:CGPointMake(100, 0)];
    [key addLineToPoint:CGPointMake(-100, 50)];
    [key addLineToPoint:CGPointMake(100, 100)];
    [key addLineToPoint:CGPointMake(0, 100)];
    [key addLineToPoint:CGPointMake(0, 25)];

    XCTAssert([slice isEqualToBezierPath:key withAccuracy:0.00001]);
}

- (void)testTrimClosedElement3
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)];
    [path addQuadCurveToPoint:CGPointMake(100, 100) controlPoint:CGPointMake(100, 0)];

    UIBezierPath *slice = [path bezierPathByTrimmingToElement:1 andTValue:0.75];

    UIBezierPath *key = [UIBezierPath bezierPath];
    [key moveToPoint:CGPointMake(0, 0)];
    [key addCurveToPoint:CGPointMake(93.75, 56.25) controlPoint1:CGPointMake(50, 0) controlPoint2:CGPointMake(81.25, 18.75)];

    XCTAssert([slice isEqualToBezierPath:key withAccuracy:0.00001]);
}

@end
