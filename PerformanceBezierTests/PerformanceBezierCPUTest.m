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

- (UIBezierPath *)generateRandomPathWithSubpaths {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointZero];

    while ([path elementCount] < 10000) {
        CGPoint dest = [self randomPointNear:[path lastPoint] close:NO];
        if (rand() % 50 == 0) {
            [path moveToPoint:dest];
        } else {
            [path addCurveToPoint:dest controlPoint1:[self randomPointNear:[path lastPoint]] controlPoint2:[self randomPointNear:dest]];
        }
    }

    return path;
}

- (void)testTotalLengthCache {
    // This is an example of a performance test case.
    [self measureBlock:^{
        for (NSInteger i=0; i<10; i++) {
            // Put the code you want to measure the time of here.
            UIBezierPath *path = [self generateRandomPath];

            for (NSInteger i=0; i<[path elementCount]; i++) {
                [path lengthOfPathThroughElement:i withAcceptableError:0.5];
            }
        }
    }];
}

- (void)testTotalLengthCache2 {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        UIBezierPath *path = [self generateRandomPath];

        for (NSInteger i=0; i<[path elementCount]; i++) {
            [path lengthOfPathThroughElement:i withAcceptableError:0.5];
        }

        sleep(6);

        for (NSInteger i=0; i<[path elementCount]; i++) {
            [path lengthOfPathThroughElement:i withAcceptableError:0.5];
        }
    }];
}

- (void)testElementLengthCache {
    // This is an example of a performance test case.
    [self measureBlock:^{
        for (NSInteger i=0; i<10; i++) {
            // Put the code you want to measure the time of here.
            UIBezierPath *path = [self generateRandomPath];

            for (NSInteger i=0; i<[path elementCount]; i++) {
                [path lengthOfElement:i withAcceptableError:0.5];
            }
        }
    }];
}

- (void)testSubrangeLengthCache {
    // This is an example of a performance test case.
    [self measureBlock:^{
        for (NSInteger i=0; i<10; i++) {
            // Put the code you want to measure the time of here.
            UIBezierPath *path = [self generateRandomPath];

            for (NSInteger i=0; i<[path elementCount] - 1; i++) {
                [path subpathRangeForElement:i];
            }
        }
    }];
}

@end
