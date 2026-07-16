//
//  HwTimeZone.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2021/6/24.
//

#import <Foundation/Foundation.h>
#import "HwDeviceDefines.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 @class HwTimeZone
 @brief 时区数据模型
 */
@interface HwTimeZone : NSObject

/*! @brief
 时间区域 [timezone]
 */
@property(nonatomic, assign) HwTimezoneArea area;
/*! @brief
 小时[hour]
 */
@property(nonatomic, assign) NSInteger hour;
/*! @brief
 分钟[minute]
 */
@property(nonatomic, assign) NSInteger min;
/*! @brief
 城市[city]
 */
@property(nonatomic, copy) NSString *city;
/*! @brief
 国家[country]
 */
@property(nonatomic, copy) NSString *country;

@end

NS_ASSUME_NONNULL_END
