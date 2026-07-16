//
//  HwDontDisturbModel.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2021/6/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/*!
 @class HwDontDisturbModel
 @brief 勿打扰数据模型
 */
@interface HwDontDisturbModel : NSObject

/*! @brief
 开关 [switch]
 */
@property(nonatomic, assign) BOOL S;
/*! @brief
 开始小时 [start hour]
 */
@property(nonatomic, assign) NSInteger startHour;
/*! @brief
 开始分钟 [start min]
 */
@property(nonatomic, assign) NSInteger startMin;
/*! @brief
 结束小时 [end hour]
 */
@property(nonatomic, assign) NSInteger endHour;
/*! @brief
 结束分钟 [end minute]
 */
@property(nonatomic, assign) NSInteger endMin;

@end

NS_ASSUME_NONNULL_END
