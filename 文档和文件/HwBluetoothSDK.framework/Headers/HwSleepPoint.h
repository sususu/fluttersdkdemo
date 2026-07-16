//
//  HwSleepPoint.h
//  Pods
//
//  Created by HuaWo on 2022/6/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 睡眠状态[sleep status]
 
 - HwSleepStatusDeep: 深睡[deep sleep]
 */
typedef NS_ENUM(NSInteger, HwSleepStatus) {
    HwSleepStatusDeep = 0,          // deep sleep
    HwSleepStatusLight = 1,         // light sleep
    HwSleepStatusAwake = 2,         // awake state
    HwSleepStatusPrepare = 3,       // prepare fall in sleep
    HwSleepStatusREM = 5,             //REM of sleep
    HwSleepStatusEnterNapSleep = 0x10,   // enter nap sleep mode
    HwSleepStatusEnterSleepMode = 0x10,   // enter sleep mode
    HwSleepStatusExitSleepMode1 = 0x11,   // exit sleep mode (not preset sleep)
    HwSleepStatusExitSleepMode2 = 0x12    // exit sleep mode (preset sleep)
};



/*!
 @class HwSleepPoint
 @brief 睡眠数据模型[sleep data models]
 */
@interface HwSleepPoint : NSObject
/**
 This value cannot be used as a unique identifier for data.
 It is only useful for logging and debug.
 */
@property(nonatomic, assign) NSUInteger index;
/*! @brief
 时间点[Interval time]
 */
@property(nonatomic, assign) NSTimeInterval time;
/*! @brief
 睡眠状态[sleep status]
 */
@property(nonatomic, assign) HwSleepStatus status;

@end

NS_ASSUME_NONNULL_END
