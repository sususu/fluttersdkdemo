//
//  HwVibrationModel.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2021/6/24.
//

#import <Foundation/Foundation.h>
#import "HwDeviceDefines.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 @class HwVibrationModel
 @brief 震动数据模型
 */
@interface HwVibrationModel : NSObject

/*! @brief
 震动类型 [vibration type]
 @see HwVibrationType
 */
@property(nonatomic, assign) HwVibrationType type;
/*! @brief
 震动状态 [vibration state]
 @see HwVibrationState
 */
@property(nonatomic, assign) HwVibrationState state;

@end

NS_ASSUME_NONNULL_END
