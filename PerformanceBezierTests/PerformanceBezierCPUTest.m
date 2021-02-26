//
//  PerformanceBezierCPUTest.m
//  PerformanceBezierTests
//
//  Created by Adam Wulf on 2/26/21.
//  Copyright © 2021 Milestone Made. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PerformanceBezierAbstractTest.h"

@interface PerformanceBezierCPUTest : PerformanceBezierAbstractTest

@end

@implementation PerformanceBezierCPUTest

- (CGPoint) randomPointNear:(CGPoint)otherPoint {
    return [self randomPointNear:otherPoint close:YES];
}

- (CGPoint) randomPointNear:(CGPoint)otherPoint close:(BOOL)close {
    NSInteger delta = close ? 4 : 10;
    // + or - 4 or 10pts with 2 significant fractional digits
    return CGPointMake(otherPoint.x + rand() % (delta * 2 * 100) / 100.0 - 10, otherPoint.y + rand() % 2000 / 100.0 - 10);
}

- (UIBezierPath *)generateRandomPath {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointZero];

    while ([path elementCount] < 10000) {
        CGPoint dest = [self randomPointNear:[path lastPoint] close:NO];
        [path addCurveToPoint:dest controlPoint1:[self randomPointNear:[path lastPoint]] controlPoint2:[self randomPointNear:dest]];
    }

    return path;
}

- (void)testPerformanceExample {

    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        UIBezierPath *path = [self generateRandomPath];
        [path closePath];

        for (NSInteger i=0; i<[path elementCount]; i++) {
            [path lengthOfPathThroughElement:i withAcceptableError:0.5];
        }
    }];
}

@end
