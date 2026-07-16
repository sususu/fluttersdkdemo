//
//  HwBluetoothCenter+Customize.h
//  CocoaLumberjack
//
//  Created by sujiang on 2020/8/27.
// 用户自定义蓝牙协议

#import "HwBluetoothCenter.h"

#define HwKeyCustomizeTargetNowValue @"HwKeyCustomizeTargetNowValue"
#define HwKeyCustomizeTargetTargetValue @"HwKeyCustomizeTargetTargetValue"
#define HwKeyCustomizeTargetType  @"HwKeyCustomizeTargetType"

#define HwKeyCustomizeAlarmThresholdMinValue @"HwKeyCustomizeAlarmThresholdMinValue"
#define HwKeyCustomizeAlarmThresholdMaxValue @"HwKeyCustomizeAlarmThresholdMaxValue"
#define HwKeyCustomizeAlarmThresholdSwitch  @"HwKeyCustomizeAlarmThresholdSwitch"
#define HwKeyCustomizeAlarmThresholdType  @"HwKeyCustomizeAlarmThresholdType"

NS_ASSUME_NONNULL_BEGIN

/*!
 自定义目标类型[Customize Target Type]
 
 - HwCustomizeWaterTargetType: 喝水量[water]
 - HwCustomizeWeightTargetType: 体重[weight]
 */
typedef NS_ENUM(NSInteger, HwCustomizeTargetType) {
    HwCustomizeWaterTargetType = 0x00,
    HwCustomizeWeightTargetType = 0x01
};

/*!
 自定义目标类型[Customize alarm threshold Type]
 
 - HwCustomizeAlarmTemperatureType: 体温[temperature]
 */
typedef NS_ENUM(NSInteger, HwCustomizeAlarmType) {
    HwCustomizeAlarmTemperatureType = 0x00 //（单位:℃ *10）
};

@interface HwBluetoothCenter (Customize)
#pragma mark -- 用户<自定义目标> 喝水与体重

/*!@brief
 获取用户<自定义目标>对应值的当前值与目标值
 @param type 查询类型[HwCustomizeTargetType]
 @param callback 当前值/目标值 回调[@{@"nowData":@"",@"targetData":@""} callback]
 @return 任务[task]
 */
- (HwBluetoothTask *)getCustomizeTargetDataByType:(HwCustomizeTargetType)type callback:(HwBCDictionaryCallback)callback;

/*!@brief
添加用户<自定义目标>类型对应的值/目标值
@param type 查询类型[HwCustomizeTargetType]
@param setNum 设置值[setNum]
@param targetNum 目标值[targetNum]
@param callback 回调[callback]
@return 任务[task]
*/
- (HwBluetoothTask *)addCustomizeTargetDataByType:(HwCustomizeTargetType)type withSetData:(NSInteger)setNum withTargetData:(NSInteger)targetNum callback:(HwBoolCallback)callback;

#pragma mark -- 用户<自定义报警阈值> 体温

/*! @brief
 获取用户<自定义报警阈值>的值[get the customize alarm threshold value]
 @param type HwCustomizeAlarmType
 @param callback 回调[callback]
 @return 任务[task]
 */
- (HwBluetoothTask *) getCustomizeAlarmThresholdValueByType:(HwCustomizeAlarmType)type withCallback:(HwBCDictionaryCallback)callback;

/*! @brief
 设置用户<自定义报警阈值>的值[set the customize alarm threshold value]
 @param type HwCustomizeAlarmType
 @param max 最大值温度℃[the max ℃]
 @param min 最小值温度℃[the min ℃]
 @param off 开关[on and off]
 @param callback 回调[callback]
 @return 任务[task]
 */
- (HwBluetoothTask *) setCustomizeAlarmThresholdValueByType:(HwCustomizeAlarmType)type
                                                    withmin:(double)min
                                                        Max:(double)max
                                                  switchOff:(BOOL)off
                                             callback:(HwBoolCallback)callback;


@end

NS_ASSUME_NONNULL_END
