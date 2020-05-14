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
    [simplePath moveToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 99)];

    UIBezierPath* trimmedPath = [UIBezierPath bezierPath];
    [trimmedPath moveToPoint:CGPointMake(200, 100)];
    [trimmedPath addLineToPoint:CGPointMake(200, 99)];

    XCTAssertEqualObjects([simplePath bezierPathByTrimmingFromElement:2], trimmedPath);
}

@end
