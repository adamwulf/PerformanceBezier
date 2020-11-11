//
//  UIBezierPath+Description.m
//  LooseLeaf
//
//  Created by Adam Wulf on 12/17/13.
//  Copyright (c) 2013 Milestone Made, LLC. All rights reserved.
//

#import "UIBezierPath+Description.h"
#import "JRSwizzle.h"
#import "UIBezierPath+NSOSX.h"

#define kShowSwift YES

@implementation UIBezierPath (Description)


//
// create a human readable objective-c string for
// the path. this lets a dev easily print out the bezier
// from the debugger, and copy the result directly back into
// code. Perfect for printing out runtime generated beziers
// for use later in tests.
- (NSString *)swizzle_description
{
    return [self descriptionInSwift:kShowSwift];
}

//
// create a human readable objective-c string for
// the path. this lets a dev easily print out the bezier
// from the debugger, and copy the result directly back into
// code. Perfect for printing out runtime generated beziers
// for use later in tests.
- (NSString *)descriptionInSwift:(BOOL)showSwift
{
    __block NSString *str = showSwift ? @"path = UIBezierPath()\n" : @"path = [UIBezierPath bezierPath];\n";
    [self iteratePathWithBlock:^(CGPathElement ele, NSUInteger idx) {
      if (ele.type == kCGPathElementAddCurveToPoint) {
          CGPoint curveTo = ele.points[2];
          CGPoint ctrl1 = ele.points[0];
          CGPoint ctrl2 = ele.points[1];
          if (showSwift) {
              str = [str stringByAppendingFormat:@"path.addCurve(to: CGPoint(x: %@, y: %@), controlPoint1: CGPoint(x: %@, y: %@), controlPoint2: CGPoint(x: %@, y: %@))\n", @(curveTo.x), @(curveTo.y), @(ctrl1.x), @(ctrl1.y), @(ctrl2.x), @(ctrl2.y)];
          } else {
              str = [str stringByAppendingFormat:@"[path addCurveToPoint:CGPointMake(%@, %@) controlPoint1:CGPointMake(%@, %@) controlPoint2:CGPointMake(%@, %@)];\n", @(curveTo.x), @(curveTo.y), @(ctrl1.x), @(ctrl1.y), @(ctrl2.x), @(ctrl2.y)];
          }
      } else if (ele.type == kCGPathElementAddLineToPoint) {
          CGPoint lineTo = ele.points[0];
          if (showSwift) {
              str = [str stringByAppendingFormat:@"path.addLine(to: CGPoint(x: %@, y: %@))\n", @(lineTo.x), @(lineTo.y)];
          } else {
              str = [str stringByAppendingFormat:@"[path addLineToPoint:CGPointMake(%@, %@)];\n", @(lineTo.x), @(lineTo.y)];
          }
      } else if (ele.type == kCGPathElementAddQuadCurveToPoint) {
          CGPoint curveTo = ele.points[1];
          CGPoint ctrl = ele.points[0];
          if (showSwift) {
              str = [str stringByAppendingFormat:@"path.addQuadCurve(to: CGPoint(x: %@, y: %@), controlPoint:CGPoint(x: %@, y: %@))\n", @(curveTo.x), @(curveTo.y), @(ctrl.x), @(ctrl.y)];
          } else {
              str = [str stringByAppendingFormat:@"[path addQuadCurveToPoint:CGPointMake(%@, %@) controlPoint:CGPointMake(%@, %@)];\n", @(curveTo.x), @(curveTo.y), @(ctrl.x), @(ctrl.y)];
          }
      } else if (ele.type == kCGPathElementCloseSubpath) {
          [self closePath];
          if (showSwift) {
              str = [str stringByAppendingString:@"path.close()\n"];
          } else {
              str = [str stringByAppendingString:@"[path closePath];\n"];
          }
      } else if (ele.type == kCGPathElementMoveToPoint) {
          CGPoint moveTo = ele.points[0];
          if (showSwift) {
              str = [str stringByAppendingFormat:@"path.move(to: CGPoint(x: %@, y: %@))\n", @(moveTo.x), @(moveTo.y)];
          } else {
              str = [str stringByAppendingFormat:@"[path moveToPoint:CGPointMake(%@, %@)];\n", @(moveTo.x), @(moveTo.y)];
          }
      }
    }];
    return str;
}


+ (void)load
{
    @autoreleasepool {
        NSError *error = nil;
        [UIBezierPath mmpb_swizzleMethod:@selector(description)
                              withMethod:@selector(swizzle_description)
                                   error:&error];
    }
}
@end
