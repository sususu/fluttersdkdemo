//
//  HwBluetoothCenter+Muslim.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2024/10/28.
//

#import "HwBluetoothCenter.h"
#import "HwPrayerBeadsSwitch.h"
#import "HwMuslimWorshipSwitch.h"
#import "HwMuslimDayAlert.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^HwMuslimWorshipSwitchesCallback)(NSArray<HwMuslimWorshipSwitch *> *_Nonnull swList, NSError *_Nullable error);
typedef void (^HwHwPrayerBeadsSwitchCallback)(HwPrayerBeadsSwitch *_Nonnull sw, NSError *_Nullable error);
typedef void (^HwCollectedAllahIndexsCallback)(NSArray<NSNumber *> *_Nonnull list, NSError *_Nullable error);

@interface HwBluetoothCenter (Muslim)

// 朝拜开关相关
- (HwBluetoothTask *_Nullable) setMuslimWorshipSwitches:(NSArray<HwMuslimWorshipSwitch *> *_Nonnull)swList
                                               callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getMuslimWorshipSwitchesWithCallback:(HwMuslimWorshipSwitchesCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) setMuslimWorshipMasterSwitche:(BOOL)on callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getMuslimWorshipMasterSwitcheWithCallback:(HwBoolCallback _Nullable)callback;


- (HwBluetoothTask *_Nullable) setPrayerBeadsSwitch:(HwPrayerBeadsSwitch *_Nonnull)sw
                                           callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) setPrayerBeadsSwitchState:(BOOL)on
                                                callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) setPrayerBeadsSwitchStartHour:(NSInteger)startHour
                                                 startMinute:(NSInteger)startMinute
                                                    callback:(HwBoolCallback)callback;
- (HwBluetoothTask *_Nullable) setPrayerBeadsSwitchEndHour:(NSInteger)startHour
                                                 endMinute:(NSInteger)startMinute
                                                  callback:(HwBoolCallback)callback;

- (HwBluetoothTask *_Nullable) setPrayerBeadsSwitchInterval:(NSTimeInterval)interval
                                                    callback:(HwBoolCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) setPrayerBeadsSwitchInteractiveType:(HwPrayerBeadsInteractiveType)type
                                                          callback:(HwBoolCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) getPrayerBeadsSwitchWithCallback:(HwHwPrayerBeadsSwitchCallback _Nonnull)callback;

- (HwBluetoothTask *_Nullable) getWorshipCompassStyleWithCallback:(HwBCIntegerCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) setWorshipCompassStyle:(NSInteger)style
                                             callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getCollectedAllahIndexsWithCallback:(HwCollectedAllahIndexsCallback)callback;
- (HwBluetoothTask *_Nullable) setCollectedAllahIndexs:(NSArray<NSNumber *> *_Nonnull)list
                                              callback:(HwBoolCallback)callback;

// 朝拜提醒相关
- (HwBluetoothTask *_Nullable) setPrayerAlertTime:(NSArray<HwMuslimDayAlert *> *_Nonnull)dayAlertList
                                         callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getPrayerAlertTimeWithCallback:(HwBoolCallback _Nullable)callback;


@end

NS_ASSUME_NONNULL_END
