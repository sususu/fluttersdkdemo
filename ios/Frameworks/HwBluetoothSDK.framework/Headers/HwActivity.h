//
//  HwActivity.h
//  Pods
//
//  Created by HuaWo on 2022/6/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @class HwActivity
 @brief Activity data model
 */
@interface HwActivity : NSObject
/**
 This value cannot be used as a unique identifier for data.
 It is only useful for logging and debug.
 */
@property(nonatomic, assign) NSUInteger index;

/*! @brief
 The generation time of this data, it's unit is second
 */
@property(nonatomic, assign) NSTimeInterval time;
/*! @brief
 steps
 */
@property(nonatomic, assign) NSUInteger step;
/*! @brief
 Calorie
 */
@property(nonatomic, assign) NSUInteger calorie;
/*! @brief
 Static Calorie
 */
@property(nonatomic, assign) NSUInteger staticCalorie;
/*! @brief
 It's unit is meter.(米)
 */
@property(nonatomic, assign) NSUInteger distance;
/*! @brief
 How many minutes.
 */
@property(nonatomic, assign) NSUInteger duration;

/*! @brief
 Average heartRate bpm for this moment
 */
@property(nonatomic, assign) NSUInteger avgBpm;

@end

NS_ASSUME_NONNULL_END
