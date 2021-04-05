//
//  PerformanceBezier.h
//  PerformanceBezier
//
//  Created by Adam Wulf on 2/1/15.
//  Copyright (c) 2015 Milestone Made, LLC. All rights reserved.
//

#define CGPointNotFound CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX)

#if COCOAPODS
#import <PerformanceBezier/UIBezierPath+Center.h>
#import <PerformanceBezier/UIBezierPath+Clockwise.h>
#import <PerformanceBezier/UIBezierPath+Description.h>
#import <PerformanceBezier/UIBezierPath+Equals.h>
#import <PerformanceBezier/UIBezierPath+NSOSX.h>
#import <PerformanceBezier/UIBezierPath+Ahmed.h>
#import <PerformanceBezier/UIBezierPath+Performance.h>
#import <PerformanceBezier/UIBezierPath+Trim.h>
#import <PerformanceBezier/UIBezierPath+Util.h>
#import <PerformanceBezier/UIBezierPathProperties.h>
#import <Foundation/Foundation.h>
#else
#import "UIBezierPath+Center.h"
#import "UIBezierPath+Clockwise.h"
#import "UIBezierPath+Description.h"
#import "UIBezierPath+Equals.h"
#import "UIBezierPath+NSOSX.h"
#import "UIBezierPath+Ahmed.h"
#import "UIBezierPath+Performance.h"
#import "UIBezierPath+Trim.h"
#import "UIBezierPath+Util.h"
#import "UIBezierPathProperties.h"
#import <Foundation/Foundation.h>
#endif
