//
//  UIBezierPath+Description.h
//  LooseLeaf
//
//  Created by Adam Wulf on 12/17/13.
//  Copyright (c) 2013 Milestone Made, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBezierPath (Description)

/// Generate a string of Obj-C or Swift source code to build this same path
- (NSString *)descriptionInSwift:(BOOL)showSwift;

@end
