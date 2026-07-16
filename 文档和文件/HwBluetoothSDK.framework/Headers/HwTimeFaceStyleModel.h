//
//  HwTimeFaceStyleModel.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2021/6/24.
//

#import <Foundation/Foundation.h>
#import "HwDeviceDefines.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 @class HwTimeFaceStyleModel
 @brief 时间界面样式
 */
@interface HwTimeFaceStyleModel : NSObject

@property(nonatomic, assign) HwDateStyle dateStyle;
@property(nonatomic, assign) HwTimeStyle timeStyle;
@property(nonatomic, assign) HwBatteryStyle batteryStyle;
@property(nonatomic, assign) HwLunarStyle lunarStyle;
@property(nonatomic, assign) HwScreenStyle screenStyle;
@property(nonatomic, assign) HwUnitStyle unitStyle;
// 手表背景样式（从0索引开始，对应到UI、UE设计上）
@property(nonatomic, assign) NSInteger backgroundStyle;
@property(nonatomic, assign) HwHeartRateStyle heartRateStyle;
@property(nonatomic, assign) HwUsernameStyle usernameStyle;


@end

NS_ASSUME_NONNULL_END
