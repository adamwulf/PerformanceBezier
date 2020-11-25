//
//  UIBezierPath+Util.h
//  PerformanceBezier
//
//  Created by Adam Wulf on 5/20/15.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIBezierPath (Util)

- (UIBezierPath*)buildEmptyPath;

/// A mutable dictionary that will be maintained with this path. Store any key/value pairs
/// and these will stay with the path. The userInfo will be shallow copied to any path
/// that has been clipped or copied from this path
- (NSMutableDictionary<NSString *, NSObject<NSCoding> *> *)userInfo;

+ (CGFloat)lengthOfBezier:(const CGPoint[_Nonnull 4])bez withAccuracy:(CGFloat)accuracy;

+ (void)subdivideBezierAtT:(const CGPoint[_Nonnull 4])bez bez1:(CGPoint[_Nonnull 4])bez1 bez2:(CGPoint[_Nonnull 4])bez2 t:(CGFloat)t;

+ (CGFloat)distanceOfPointToLine:(CGPoint)point start:(CGPoint)start end:(CGPoint)end;

+ (CGFloat)distance:(const CGPoint)p1 p2:(const CGPoint)p2;

+ (CGPoint)bezierTangentAtT:(const CGPoint[_Nonnull 4])bez t:(CGFloat)t;

+ (CGFloat)subdivideBezier:(const CGPoint[_Nonnull 4])bez bez1:(CGPoint[_Nonnull 4])bez1 bez2:(CGPoint[_Nonnull 4])bez2 atLength:(CGFloat)length acceptableError:(CGFloat)acceptableError;

+ (CGFloat)subdivideBezier:(const CGPoint[_Nonnull 4])bez bez1:(CGPoint[_Nonnull 4])bez1 bez2:(CGPoint[_Nonnull 4])bez2 atLength:(CGFloat)length acceptableError:(CGFloat)acceptableError withCache:(nullable CGFloat *)subBezierLengthCache;

+ (CGPoint)lineSegmentIntersectionPointA:(CGPoint)A pointB:(CGPoint)B pointC:(CGPoint)C pointD:(CGPoint)D;

@end

NS_ASSUME_NONNULL_END
