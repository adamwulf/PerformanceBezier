//
//  PerformanceBezierEqualsTest.m
//  PerformanceBezierTests
//
//  Created by Adam Wulf on 5/22/20.
//  Copyright © 2020 Milestone Made. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PerformanceBezierAbstractTest.h"

@interface PerformanceBezierEqualsTest : PerformanceBezierAbstractTest

@end

@implementation PerformanceBezierEqualsTest

- (void)testEqualsExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    UIBezierPath *path1 = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 100, 200)];
    UIBezierPath *path2 = [path1 copy];
    
    XCTAssertEqualObjects(path1, path2);
    XCTAssert([path1 isEqualToBezierPath:path2]);
}

- (void)testAlmostEqualsExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    UIBezierPath *path1 = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 100, 200)];
    UIBezierPath *path2 = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 100.1, 200)];
    
    XCTAssert([path1 isEqualToBezierPath:path2 withAccuracy:.1]);
}

- (void)testFlatOutline {
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineCapStyle = kCGLineCapButt;
    path.lineWidth = 50;
    [path moveToPoint:CGPointMake(310.430087, 518.485281)];
    [path addLineToPoint:CGPointMake(320.279654, 511.430087)];

    CGPathRef cgCopy = CGPathCreateCopyByStrokingPath(path.CGPath,
                                                      NULL,
                                                      path.lineWidth,
                                                      path.lineCapStyle,
                                                      path.lineJoinStyle,
                                                      path.miterLimit);
    UIBezierPath *copyBez = [UIBezierPath bezierPathWithCGPath:cgCopy];

    XCTAssertEqual(path.isFlat, copyBez.isFlat);
}

@end
