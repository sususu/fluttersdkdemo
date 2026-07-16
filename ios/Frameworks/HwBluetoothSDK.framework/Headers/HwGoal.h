//
//  HwGoal.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2022/2/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*! @brief
 运动目标类型[sport goal type ]
 
 - HwGoalTypeStep: 步数[step]
 - HwGoalTypeCaloris: 卡路里[calorie]
 - HwGoalTypeDistance: 距离[distance]
 - HwGoalTypeSleep: 睡眠[sleep]
 - HwGoalTypeDuration: 运动时间[sport time]
 - HwGoalTypeOTDistance:扩展公制距离的目标值[sport OTDistance]
 - HwGoalTypeOTDistanceMile:扩展英制距离的目标值[sport OTDistanceMile]
 */
typedef NS_ENUM(NSInteger, HwGoalType) {
    HwGoalTypeStep = 0,
    HwGoalTypeCaloris = 1,
    HwGoalTypeDistance = 2,
    HwGoalTypeSleep = 3,
    HwGoalTypeDuration = 4,
    HwGoalTypeOTDistance = 5,
    HwGoalTypeOTDistanceMile = 6,
};

/*!
 @class HwGoal
 @brief 目标数据模型 [target data models]
 */
@interface HwGoal : NSObject

/*! @brief
 步数（步）[steps(step)]
 */
@property(nonatomic, assign) NSInteger step;            // 步数[steps]
/*! @brief
 距离（米）[Distance(meter)]
 */
@property(nonatomic, assign) NSInteger distance;        // 距离[Distance]
/*! @brief
 卡路里（卡）[Calorie]
 */
@property(nonatomic, assign) NSInteger calorie;         // 卡[calorie]
/*! @brief
 睡眠（分钟）[sleep]
 */
@property(nonatomic, assign) NSInteger sleep;           // 分种[minute]
/*! @brief
 运动时间（分钟）[movement time]
 */
@property(nonatomic, assign) NSInteger duration;        // 分种[minute]
/*! @brief
 距离（0.1公里）[oTDistance(meter)]
 */
@property(nonatomic, assign) NSInteger oTDistance;        // 扩展公制距离的目标值[oTDistance]
/*! @brief
 距离（0.1英里）[oTDistanceMile(mile)]
 */
@property(nonatomic, assign) NSInteger oTDistanceMile;        // 扩展英制距离的目标值[oTDistanceMile]

@end

NS_ASSUME_NONNULL_END
