//
//  HwPhoneScheduleReminderUnit.h
//  HwBluetoothSDK
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HwPhoneScheduleReminderUnit) {
    HwPhoneScheduleReminderUnitMinute = 0x00,
    HwPhoneScheduleReminderUnitHour = 0x01,
    HwPhoneScheduleReminderUnitDay = 0x02,
    HwPhoneScheduleReminderUnitWeek = 0x03,
    HwPhoneScheduleReminderUnitUnknown = 0xff,
};

NS_ASSUME_NONNULL_END
