//
//  HwBluetoothCenter+StatusSetting.h
//  HwBluetooth
//
//  Created by SuJiang on 2018/4/6.
//  Copyright © 2021年 huawo. All rights reserved.
//

#import "HwBluetoothCenter.h"
#import "HwBluetoothCenter+Device.h"
#import "HwSocialSwitch.h"
#import "HwSocialApp.h"
#import "HwFeatureSwitch.h"
#import "HwReminder.h"
#import "HwScheduleReminder.h"
#import "HwAlarm.h"

#pragma mark - data define

@interface HwBluetoothCenter (StatusSetting)

typedef void (^HwFeatureSwitchCallback)(NSArray<HwFeatureSwitch *> *models, NSError *error);
/**
 
 */
- (HwBluetoothTask *) getFeatureSwitchesWithCallback:(HwFeatureSwitchCallback)callback;

- (HwBluetoothTask *) setFeatureSwitchWithType:(HwFeatureSwitchType)type
                                             S:(BOOL)S
                                      callback:(HwBoolCallback)callback;

- (HwBluetoothTask *) getFeatureSwitchStateOfType:(HwFeatureSwitchType)type
                                         callback:(HwBoolCallback)callback;
// 如果没有传，默认是关闭[if it is not spread, default is off]
- (HwBluetoothTask *) setAllFeatureSwitches:(NSArray<HwFeatureSwitch *> *)models
                                   callback:(HwBoolCallback)callback;

#pragma mark - social switch
typedef void (^HwSocialSwitchesCallback)(NSArray<HwSocialSwitch *> *models, NSError *error);
typedef void (^HwSocialAppsCallback)(NSArray<HwSocialApp *> *models, NSError *error);
- (HwBluetoothTask *) getSocialSwitchesWithCallback:(HwSocialSwitchesCallback)callback;

- (HwBluetoothTask *) setSocialSwitchWithType:(HwSocialSwitchType)type
                                            S:(BOOL)S
                                     callback:(HwBoolCallback)callback;

- (HwBluetoothTask *) setSocialSwitch:(HwSocialSwitch *)ss
                             callback:(HwBoolCallback)callback;

- (HwBluetoothTask *) setSocialSwitches:(NSArray<HwSocialSwitch *> *)models
                               callback:(HwBoolCallback)callback;

- (HwBluetoothTask *) setSocialApps:(NSArray<HwSocialApp *> *)socialApps
                      readyCallback:(HwBoolCallback)readyCallback
                   progressCallback:(HwBCFloatCallback)progressCallback
                     finishCallback:(HwBoolCallback)finishCallback;

- (HwBluetoothTask *) getSocialAppsWithCallback:(HwSocialAppsCallback)callback;

typedef void (^HwReminderCallback)(HwReminder *model, NSError *error);
typedef void (^HwRemindersCallback)(NSArray<HwReminder *> *models, NSError *error);
typedef void (^HwAlarmsCallback)(NSArray<HwAlarm *> *models, NSError *error);

#pragma mark - 提醒
- (HwBluetoothTask *) getRemindAndAlarmCountWithCallback:(void(^)(NSUInteger reminderCount, NSUInteger alarmCount, NSError *error))callback;
- (HwBluetoothTask *) getRemindersWithCount:(NSInteger)num callback:(HwRemindersCallback)callback;
- (HwBluetoothTask *) getAlarmsWithCount:(NSInteger)num callback:(HwRemindersCallback)callback;
- (HwBluetoothTask *) getAvailableRemindIdentifyWithCallback:(HwBCIntegerCallback)callback;

- (HwBluetoothTask *) addReminder:(HwReminder *)reminder
                         identify:(NSUInteger)identify
                         callback:(HwBoolCallback)callback;

- (HwBluetoothTask *) editReminder:(HwReminder *)reminder callback:(HwBoolCallback)callback;
//- (HwBluetoothTask *) replaceReminder:(HwReminder *)reminder callback:(HwBoolCallback)callback;
- (HwBluetoothTask *) replaceReminder:(HwReminder *)reminder
                             identify:(NSUInteger)identify
                                count:(NSUInteger)count
                             callback:(HwBoolCallback)callback;
- (HwBluetoothTask *) deleteReminderOrAlarmByID:(NSUInteger)identify
                                       callback:(HwBoolCallback)callback;
- (HwBluetoothTask *) deleteRemindersWithCallback:(HwBoolCallback)callback;
- (HwBluetoothTask *) deleteAlarmsWithCallback:(HwBoolCallback)callback;
- (HwBluetoothTask *) setAlarmsWithCallback:(HwBoolCallback)callback;

/*
 根据type类型，查询提醒总数
  */
- (HwBluetoothTask *) getAllReminderEventCountByType:(HwReminderType)type
                                            callback:(HwBCIntegerCallback _Nonnull)callback;
/*
 根据type类型，获取提醒数据
 */
- (HwBluetoothTask *) getAllReminderEvents:(HwReminderType)type
                                  callback:(HwRemindersCallback _Nonnull)callback;
/*
 根据type类型，覆盖添加
 */
- (HwBluetoothTask *) setReminderEvent:(HwReminder *)reminder
                               identify:(NSUInteger)identify
                                  count:(NSUInteger)count
                                   type:(HwReminderType)type
                               callback:(HwBoolCallback _Nonnull)callback;

/*
 根据type类型，删除全部提醒
 */
- (HwBluetoothTask *) delAllReminderEvents:(HwReminderType)type
                                  callback:(HwBoolCallback _Nonnull)callback;

#pragma mark - 日程提醒月视图[month canlendars]
- (HwBluetoothTask *) setMonthCalendars:(NSArray *)monthCalendars
                               callback:(HwBoolCallback)callback;

#pragma mark - 日程提醒内容[remind content]
- (HwBluetoothTask *) setRemindContent:(NSString *)remindContent
                            remindTime:(NSTimeInterval)remindTime
                                   tag:(NSInteger)tag
                                  year:(NSInteger)year
                                 month:(NSInteger)month
                                   day:(NSInteger)day
                                  hour:(NSInteger)hour
                                   min:(NSInteger)min
                                second:(NSInteger)second
                               address:(NSString *)address
                              callback:(HwBoolCallback)callback;

@end
