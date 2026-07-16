//
//  HwSleep.h
//  Pods
//
//  Created by HuaWo on 2022/6/22.
//

#import <Foundation/Foundation.h>
#import "HwSleepPoint.h"

NS_ASSUME_NONNULL_BEGIN
/**
 Sleep data model
 */
@interface HwSleep : NSObject

/**
 Start time of sleep, it's unit is second.
 */
@property(nonatomic, assign) NSTimeInterval startTime;
/**
 End time of sleep, it's unit is second.
 */
@property(nonatomic, assign) NSTimeInterval endTime;
/**
 The length of waking up during the whole sleep, it's unit is second.
 */
@property(nonatomic, assign) NSUInteger awakeDuration;
/**
 The length of light sleep during the whole sleep, it's unit is second.
 */
@property(nonatomic, assign) NSUInteger lightDuration;
/**
 The length of deep sleep during the whole sleep, it's unit is second.
 */
@property(nonatomic, assign) NSUInteger deepDuration;
/**
 The length of REM during the whole sleep, it's unit is second.
 */
@property(nonatomic, assign) NSUInteger remDuration;
/**
 The length of sleep, it's unit is second.
 */
@property(nonatomic, assign) NSUInteger totalDuration;
/**
 Awake count.
 */
@property(nonatomic, assign) NSUInteger awakeCount;
/**
 Details of the sleep.
 */
@property(nonatomic, copy) NSArray<HwSleepPoint *> *sleepPoints;

+ (NSArray<HwSleep *> *) fromSleepPoints:(NSArray<HwSleepPoint *> *)sleepPoints;

/**
 Concomitant sleep
 sleepList：Sleep data array
 timeInterval： timeInterval 思澈平台传 2 * 3600 ，其他旧项目传 1 * 3600  (it's unit is second)
 */
+ (NSArray<HwSleep *> *)merge:(NSArray<HwSleep *> *)sleepList timeInterval:(NSTimeInterval)timeInterval;
+ (NSArray<HwSleep *> *)mergeNighttime:(NSArray<HwSleep *> *)sleepList
                          timeInterval:(NSTimeInterval)timeInterval
                              timezone:(NSTimeZone *)timezone;

@end

NS_ASSUME_NONNULL_END
