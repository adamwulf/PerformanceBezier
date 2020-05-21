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
}

- (void)testElementLength {
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [simplePath moveToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 99)];

    CGFloat len = [simplePath lengthOfElement:1 withAcceptableError:kIntersectionPointPrecision];
    
    XCTAssertEqual(len, 100);
}

@end
