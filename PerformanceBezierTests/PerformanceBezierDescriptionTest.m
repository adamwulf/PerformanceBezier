//
//  PerformanceBezierDescriptionTest.m
//  PerformanceBezierTests
//
//  Created by Adam Wulf on 11/11/20.
//  Copyright © 2020 Milestone Made. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PerformanceBezierAbstractTest.h"

@interface PerformanceBezierDescriptionTest : PerformanceBezierAbstractTest

@end

@implementation PerformanceBezierDescriptionTest

- (void)testObjCDescription {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 1)];
    [path addLineToPoint:CGPointMake(100, 101)];
    [path addQuadCurveToPoint:CGPointMake(200, 201) controlPoint:CGPointMake(300, 301)];
    [path addCurveToPoint:CGPointMake(400, 401) controlPoint1:CGPointMake(500, 501) controlPoint2:CGPointMake(600, 601)];
    [path addLineToPoint:CGPointMake(700.0 / 3.0, 701.0 / 3.0)];
    [path closePath];

    NSString *str = [path descriptionInSwift:NO];

    NSString *key = @"path = [UIBezierPath bezierPath];\n\
[path moveToPoint:CGPointMake(0, 1)];\n\
[path addLineToPoint:CGPointMake(100, 101)];\n\
[path addQuadCurveToPoint:CGPointMake(200, 201) controlPoint:CGPointMake(300, 301)];\n\
[path addCurveToPoint:CGPointMake(400, 401) controlPoint1:CGPointMake(500, 501) controlPoint2:CGPointMake(600, 601)];\n\
[path addLineToPoint:CGPointMake(233.3333333333333, 233.6666666666667)];\n\
[path closePath];\n";

    XCTAssertEqualObjects(str, key);
}

- (void)testSwiftDescription {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 1)];
    [path addLineToPoint:CGPointMake(100, 101)];
    [path addQuadCurveToPoint:CGPointMake(200, 201) controlPoint:CGPointMake(300, 301)];
    [path addCurveToPoint:CGPointMake(400, 401) controlPoint1:CGPointMake(500, 501) controlPoint2:CGPointMake(600, 601)];
    [path addLineToPoint:CGPointMake(700.0 / 3.0, 701.0 / 3.0)];
    [path closePath];

    NSString *str = [path descriptionInSwift:YES];

    NSString *key = @"path = UIBezierPath()\n\
path.move(to: CGPoint(x: 0, y: 1))\n\
path.addLine(to: CGPoint(x: 100, y: 101))\n\
path.addQuadCurve(to: CGPoint(x: 200, y: 201), controlPoint:CGPoint(x: 300, y: 301))\n\
path.addCurve(to: CGPoint(x: 400, y: 401), controlPoint1: CGPoint(x: 500, y: 501), controlPoint2: CGPoint(x: 600, y: 601))\n\
path.addLine(to: CGPoint(x: 233.3333333333333, y: 233.6666666666667))\n\
path.close()\n";

    XCTAssertEqualObjects(str, key);
}

@end
