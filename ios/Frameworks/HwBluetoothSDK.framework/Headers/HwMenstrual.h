//
//  HwMenstrual.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2021/6/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwMenstrual : NSObject

@property (nonatomic, assign) NSUInteger menstrualBeginTimestamp; // 月经开始时间戳
@property (nonatomic, assign) NSUInteger menstrualEndTimestamp; // 月经结束时间戳
@property (nonatomic, assign) NSUInteger ovulationBeginTimestamp; // 排卵开始时间戳
@property (nonatomic, assign) NSUInteger ovulationEndTimestamp; // 排卵结束时间戳
@property (nonatomic, assign) NSUInteger ovulationDayTimestamp; // 排卵日（当天）时间戳

@property (nonatomic, assign) NSUInteger periodDays; // 经期时长
@property (nonatomic, assign) NSUInteger cycleDays; // 周期时长
@property (nonatomic, assign) BOOL menstrualSwitch; // 经期提醒开关
@property (nonatomic, assign) BOOL contraceptionSwitch; // 避孕提醒开关

@end

NS_ASSUME_NONNULL_END
