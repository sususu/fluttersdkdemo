//
//  HwAlarm.h
//  Pods
//
//  Created by HuaWo on 2022/6/16.
//

#import <Foundation/Foundation.h>
#import "HwDeviceDefines.h"
#import "HwTimePoint.h"
#import "NSDate+HwSDK.h"

NS_ASSUME_NONNULL_BEGIN

@class HwReminder;
@interface HwAlarm : NSObject

@property(nonatomic, assign) NSInteger Id;

@property(nonatomic, strong) NSDate *date;

@property(nonatomic, assign) BOOL S;
/**
 重复周期类型：天、周、月、年
 */
@property(nonatomic, assign) HwRepeatType repeatType;
/**
 重复周期的数值，举例说明：当repeatType = day 重复周期是天
 repeatValue = 1 时，表示，每天重复一次；
 repeatValue = 1 时，表示，每两天重复一次；
 */
@property(nonatomic, assign) NSInteger repeatValue;

@property(nonatomic, strong) NSArray<HwTimePoint *> *times;

@property(nonatomic, assign) HwWeek week;

@property(nonatomic, assign) NSInteger snooze;
@property(nonatomic, copy) NSString *custom;

+ (HwAlarm *) alarmFromReminder:(HwReminder *)reminder;


@end

NS_ASSUME_NONNULL_END
