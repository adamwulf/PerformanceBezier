//
//  UIBezierPath+Ahmed.h
//  PerformanceBezier
//
//  Created by Adam Wulf on 11/18/20.
//  Copyright © 2020 Milestone Made. All rights reserved.
//
//
// This category is based on the masters thesis
// APPROXIMATION OF A BÉZIER CURVE WITH A MINIMAL NUMBER OF LINE SEGMENTS
// by Athar Luqman Ahmad
// available at http://www.cis.usouthal.edu/~hain/general/Theses/Ahmad_thesis.pdf
//
// More information available at
// http://www.cis.usouthal.edu/~hain/general/Thesis.htm


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIBezierPath (Ahmed)

@property(nonatomic, readonly) UIBezierPath *bezierPathByFlatteningPath;

@property(nonatomic, assign) BOOL isFlat;

- (UIBezierPath *)bezierPathByFlatteningPathAndImmutable:(BOOL)returnCopy;

@end

NS_ASSUME_NONNULL_END
