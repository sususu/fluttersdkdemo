/*!
 @header HwBluetoothCenter+User.h
 
 @author sujiang on 2021/4/21.
 @copyright  2021年 huawo. All rights reserved.
 */
#import "HwBluetoothCenter.h"
#import "HwStock.h"
#import "HwIndependentReminderConfig.h"
#import "HwHandwashingConfig.h"
#import "HwDrinkWaterConfig.h"
#import "HwDeviceDefines.h"

typedef void (^HwHandwashingConfigCallback)(HwHandwashingConfig *config, NSError *error);
typedef void (^HwDrinkWaterConfigCallback)(HwDrinkWaterConfig *config, NSError *error);

extern NSString *HwKeySex;
extern NSString *HwKeyBirthday;
extern NSString *HwKeyAge;
extern NSString *HwKeyUnit;
extern NSString *HwKeyHeight;
extern NSString *HwKeyWeight;
extern NSString *HwKeyBirthdayYear;
extern NSString *HwKeyBirthdayMonth;
extern NSString *HwKeyBirthdayDay;

@class HwUserInfo;
/*!
 @brief 用户相关API接口[API port]
 */
@interface HwBluetoothCenter (User)

#pragma mark - 用户信息[user's information]
/*! @brief
 设置个人信息[set personal details]
 
 @param sex 性别 0 --> 男、1 --> 女[gender]
 @param age 年龄（设备上默认的单位：岁）[age]
 @param height 身高（设备上默认的单位：cm）[height(default unit is cm)]
 @param weight 体重（设备上默认的单位：0.1KG）[weight(default unit is 0.1kg)]
 */
- (HwBluetoothTask *) setProfileWithSex:(HwSex)sex
                                    age:(NSInteger)age
                                 height:(NSInteger)height
                                 weight:(NSInteger)weight
                               callback:(HwBoolCallback)callback;
- (HwBluetoothTask *) setUserInfo:(HwUserInfo *)userInfo
                         callback:(HwBoolCallback)callback;

/*! @brief
 返回个人信息[return to personal detail]
 返回的是一个字典，key分别是[return to dictionary, key are:]
 extern NSString *HwKeySex;
 extern NSString *HwKeyAge;
 extern NSString *HwKeyUnit;
 extern NSString *HwKeyHeight;
 extern NSString *HwKeyWeight;
 
 @param callback 字典回调[dictionary callback]
 @return task
 */
- (HwBluetoothTask *) getProfileWithCallback:(HwBCDictionaryCallback)callback;

#pragma mark - 用户习惯[user's habit]
typedef void (^HwBCHandHabitCallback)(HwHandHabit handHabit, NSError *error);

/*! @brief
 获取用户带手表的习惯（左右手）[get user's habit of wearing watches]
 
 @param callback 回调[callback]
 @return task
 */
- (HwBluetoothTask *) getUserHandHabitWithCallback:(HwBCHandHabitCallback)callback;

/*! @brief
 设置用户带手表习惯[set user's habit of wearing watches]
 
 @param handHabit 左右手[handHabit]
 @param callback 回调[callback]
 @return task
 */
- (HwBluetoothTask *) setUserHandHabit:(HwHandHabit)handHabit
                              callback:(HwBoolCallback)callback;

- (HwBluetoothTask *) setStockInfo:(HwStock *)stock
                          callback:(HwBoolCallback)callback;


- (HwBluetoothTask *) getHandwashingConfigWithCallback:(HwHandwashingConfigCallback)callback;

- (HwBluetoothTask *) setHandwashingConfig:(HwHandwashingConfig *)config
                                  callback:(HwBoolCallback)callback;


- (HwBluetoothTask *) getDrinkWaterConfigWithCallback:(HwDrinkWaterConfigCallback)callback;

- (HwBluetoothTask *) setDrinkWaterConfig:(HwDrinkWaterConfig *)config
                                 callback:(HwBoolCallback)callback;

@end
