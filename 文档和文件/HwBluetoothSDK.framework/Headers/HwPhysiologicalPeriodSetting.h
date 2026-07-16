//
//  PhysiologicalPeriodSetting.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2022/7/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Physiological Period Setting class
 */
@interface HwPhysiologicalPeriodSetting : NSObject

/**
 Start date of last menstrual period, unit is second
*/
@property(nonatomic, assign) NSInteger lastMenstrualPeriodStartDate;
/**
 End date of last menstrual period, unit is second
 */
@property(nonatomic, assign) NSInteger lastMenstrualPeriodEndDate;
/**
 How many days does the menstrual period last
 */
@property(nonatomic, assign) NSInteger periodDays;
/**
 How many days is a physiological cycle
 */
@property(nonatomic, assign) NSInteger cycleDays;
/**
 Reminder switch at the beginning of menstrual period
 */
@property(nonatomic, assign) BOOL menstrualPeriodRemind;
/**
 Reminder switch at the beginning of easy pregnancy period
 */
@property(nonatomic, assign) BOOL easyPregnancyPeriodRemind;
/**
 Reminder switch at the end of menstrual period
 */
@property(nonatomic, assign) BOOL menstrualPeriodEndRemind;
/**
 Reminder switch at the end of easy pregnancy period
 */
@property(nonatomic, assign) BOOL easyPregnancyPeriodEndRemind;

@property (nonatomic, assign) NSUInteger periodReminderTime;//经期提醒时间（提前几天）
@property (nonatomic, assign) NSUInteger ovulationDayReminderTime;//排卵日提醒时间（提前几天）
@property (nonatomic, assign) NSUInteger easyPregnancyReminderTime;//易孕期提醒时间（提前几天）
@property (nonatomic, assign) NSUInteger reminderHour;//提醒时间（时）
@property (nonatomic, assign) NSUInteger reminderMin;//提醒时间（分）
@property (nonatomic, assign) BOOL predictiveSwitch;//预测提醒开关

@end

NS_ASSUME_NONNULL_END
