//
//  UIBezierPath+Debug.h
//  LooseLeaf
//
//  Created by Adam Wulf on 6/3/14.
//  Copyright (c) 2014 Milestone Made, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBezierPath (Debug)

// returns YES if the input path is equal
// to the current path. convenience wrapper
// around CGPathEqualToPath
-(BOOL) isEqualToBezierPath:(UIBezierPath*)path;

@end
