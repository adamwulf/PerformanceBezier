//
//  UIBezierPathProperties.h
//  PerformanceBezier
//
//  Created by Adam Wulf on 2/1/15.
//  Copyright (c) 2015 Milestone Made, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
    kPositionChangeUnknown = 0,
    kPositionChangeNo = -1,
    kPositionChangeYes = 1
} ElementPositionChange;

@interface UIBezierPathProperties : NSObject <NSSecureCoding>

@property(nonatomic) CGRect bounds;
@property(nonatomic) BOOL isClosed;
@property(nonatomic) BOOL knowsIfClosed;
@property(nonatomic) BOOL isFlat;
@property(nonatomic) BOOL hasLastPoint;
@property(nonatomic) CGPoint lastPoint;
@property(nonatomic) BOOL hasFirstPoint;
@property(nonatomic) CGPoint firstPoint;
@property(nonatomic) CGFloat tangentAtEnd;
@property(nonatomic) NSInteger cachedElementCount;
@property(nonatomic, retain) UIBezierPath *bezierPathByFlatteningPath;
@property(nonatomic) BOOL lastAddedElementWasMoveTo;
@property(strong, nonatomic) NSMutableDictionary *userInfo;

-(CGFloat)cachedLengthForElementIndex:(NSInteger)index acceptableError:(CGFloat)error;
-(void)cacheLength:(CGFloat)length forElementIndex:(NSInteger)index acceptableError:(CGFloat)error;

-(CGFloat)cachedLengthOfPathThroughElementIndex:(NSInteger)index acceptableError:(CGFloat)error;
-(void)cacheLengthOfPath:(CGFloat)length throughElementIndex:(NSInteger)index acceptableError:(CGFloat)error;

-(void)cacheElementIndex:(NSInteger)index changesPosition:(BOOL)changesPosition;
-(ElementPositionChange)cachedElementIndexDoesChangePosition:(NSInteger)index;

-(void)resetSubpathRangeCount;
-(void)cacheSubpathRange:(NSRange)range;
-(NSRange)subpathRangeForElementIndex:(NSInteger)elementIndex;

@end
