//
//  PerformanceBezierUtilTest.m
//  PerformanceBezierTests
//
//  Created by Adam Wulf on 11/25/20.
//  Copyright © 2020 Milestone Made. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PerformanceBezierAbstractTest.h"

@interface PerformanceBezierUtilTest : PerformanceBezierAbstractTest

@end

@implementation PerformanceBezierUtilTest

- (void)testUserInfo
{
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [[simplePath userInfo] setObject:@(10) forKey:@"anykey"];
    [simplePath moveToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 99)];

    UIBezierPath *copiedPath = [simplePath copy];
    UIBezierPath *trimmedPath = [simplePath bezierPathByTrimmingToElement:1 andTValue:.75];

    XCTAssertNotNil([[simplePath userInfo] objectForKey:@"anykey"]);
    XCTAssertEqualObjects(@(10), [[simplePath userInfo] objectForKey:@"anykey"]);
    XCTAssertEqualObjects([[copiedPath userInfo] objectForKey:@"anykey"], [[simplePath userInfo] objectForKey:@"anykey"]);
    XCTAssertEqualObjects([[trimmedPath userInfo] objectForKey:@"anykey"], [[simplePath userInfo] objectForKey:@"anykey"]);

    [[simplePath userInfo] setObject:@(20) forKey:@"otherKey"];
    XCTAssertEqualObjects(@(20), [[simplePath userInfo] objectForKey:@"otherKey"]);
    XCTAssertNil([[copiedPath userInfo] objectForKey:@"otherKey"]);
}

- (void)testUserInfoCopy
{
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [[simplePath userInfo] setObject:@(10) forKey:@"anykey"];
    [simplePath moveToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 99)];

    UIBezierPath *copiedPath = [simplePath copy];

    [copiedPath applyTransform:CGAffineTransformMakeScale(2, 2)];

    [[simplePath userInfo] setObject:@(100) forKey:@"anykey"];

    // copied path has old value
    XCTAssertNotNil([[simplePath userInfo] objectForKey:@"anykey"]);
    XCTAssertEqualObjects(@(100), [[simplePath userInfo] objectForKey:@"anykey"]);
    XCTAssertEqualObjects(@(10), [[copiedPath userInfo] objectForKey:@"anykey"]);
}

- (void)testUserInfoArchiving
{
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [simplePath moveToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 99)];
    [[simplePath userInfo] setObject:[UIColor blackColor] forKey:@"color"];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:simplePath];
    UIBezierPath *path = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    XCTAssertNotNil(path);
    XCTAssertEqualObjects([[path userInfo] objectForKey:@"color"], [UIColor blackColor]);
}

- (void)testUserInfoArchiving2
{
    UIColor *color = [UIColor colorWithRed:255 green:128 blue:234 alpha:0.43];
    UIBezierPath* simplePath = [UIBezierPath bezierPath];
    [simplePath moveToPoint:CGPointMake(100, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 100)];
    [simplePath addLineToPoint:CGPointMake(200, 99)];
    [[simplePath userInfo] setObject:color forKey:@"color"];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:simplePath];
    UIBezierPath *path = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    XCTAssertNotNil(path);
    XCTAssertEqualObjects([[path userInfo] objectForKey:@"color"], color);
}

@end
