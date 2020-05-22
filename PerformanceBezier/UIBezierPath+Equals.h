//
//  UIBezierPath+Equals.h
//  LooseLeaf
//
//  Created by Adam Wulf on 6/3/14.
//  Copyright (c) 2014 Milestone Made, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBezierPath (Equals)

// returns YES if the input path is equal
// to the current path. convenience wrapper
// around CGPathEqualToPath
- (BOOL)isEqualToBezierPath:(UIBezierPath *)path;

// returns YES if each point in each element of
// our path is within accuracy distance of the other
// path's element's point
- (BOOL)isEqualToBezierPath:(UIBezierPath *)path withAccuracy:(CGFloat)accuracy;

@end
