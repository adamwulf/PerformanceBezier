//
//  UIBezierPath+Debug.m
//  LooseLeaf
//
//  Created by Adam Wulf on 6/3/14.
//  Copyright (c) 2014 Milestone Made, LLC. All rights reserved.
//

#import "UIBezierPath+Debug.h"
#import "PerformanceBezier.h"

@implementation UIBezierPath (Debug)

-(BOOL) isEqualToBezierPath:(UIBezierPath*)path{
    return CGPathEqualToPath(self.CGPath, path.CGPath);
}

@end
