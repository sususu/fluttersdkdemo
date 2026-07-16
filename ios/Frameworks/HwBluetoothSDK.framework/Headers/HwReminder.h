//
//  HwReminder.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2022/2/14.
//

#import <Foundation/Foundation.h>
#import "HwDeviceDefines.h"
#import "HwTimePoint.h"
#import "HwAlarm.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *HwKeyReminderVibration;
extern NSString *HwKeyReminderType;
extern NSString *HwKeyReminderHour;
extern NSString *HwKeyReminderMin;
extern NSString *HwKeyReminderState;
extern NSString *HwKeyReminderIndex;
extern NSString *HwKeyReminderWeek;
extern NSString *HwKeyReminderCustom;
extern NSString *HwKeyReminderYear;
extern NSString *HwKeyReminderMonth;
extern NSString *HwKeyReminderDay;


typedef NS_ENUM(NSInteger, HwReminderType) {
    HwReminderTypeEat = 0x00,       // 吃饭[eat]
    HwReminderTypeTakePills = 0x01, // 吃药[take pills]
    HwReminderTypeDrinkWater = 0x02,// 喝水[drinkwater]
    HwReminderTypeSleep = 0x03,     // 睡觉[sleep]
    HwReminderTypeAwake = 0x04,     // 清醒[awake]
    HwReminderTypeSport = 0x05,     // 运动[sport]
    HwReminderTypeMeeting = 0x06,   // 会议[meeting]
    HwReminderTypeCustom = 0x07,    // 自定义[custom]
    HwReminderTypeBills = 0x08,
    HwReminderTypePersonnel = 0x09,
    HwReminderTypeWorkMethod = 0x0A // 255工作法[255WorkMethod]
};

/**
 提醒的震动类型（zetime忽略）[remind vibrant type]
 
 - HwReminderVibrantTypeOnceShort:    单次短震动[once short vibrant]
 */
typedef NS_ENUM(NSInteger, HwReminderVibrantType)
{
    HwReminderVibrantTypeOnceShort = 0x00,        // 单次短震动[once short vibrant]
    HwReminderVibrantTypeSpanTwiceShort = 0x01,   // 间歇2次短震动[span twice short vibrant]
    HwReminderVibrantTypeSpanLong = 0x02,         // 间歇长震动[span long vibrant]
};

/**
 提醒操作事件[remind operation events]
 
 - HwReminderEventAdd: 添加[add]
 - HwReminderEventEdit: 编辑[edit]
 - HwReminderEventDelete: 删除[delete]
 - HwReminderEventDeleteAll: 删除所有[delete all]
 */
typedef NS_ENUM(NSInteger, HwReminderEvent) {
    HwReminderEventAdd = 0x00,
    HwReminderEventEdit = 0x01,
    HwReminderEventDelete = 0x02,
    HwReminderEventDeleteAll = 0x03
};

@interface HwReminder : NSObject

/**
 Id
 */
@property(nonatomic, assign) NSInteger Id;
/**
 Reminder type
 */
@property(nonatomic, assign) HwReminderType type;
/**
 Switch
 */
@property(nonatomic, assign) BOOL S;
/**
 Year
 */
@property(nonatomic, assign) NSInteger year;
@property(nonatomic, assign) NSInteger month;
@property(nonatomic, assign) NSInteger day;
@property(nonatomic, assign) NSInteger hour;
@property(nonatomic, assign) NSInteger min;

/**
 重复周期类型：天、周、月、年
 */
@property(nonatomic, assign) HwRepeatType repeatType;
/**
 重复周期的数值，举例说明：当repeatType = day 重复周期是天
 repeatValue = 1 时，表示，每天重复一次；
 repeatValue = 1 时，表示，每两天重复一次；
 */
@property(nonatomic, assign) NSInteger repeatValue;
//时间数组m，具体格式为 [[12, 0], [11, 30], [10, 15], ...]
// 表示为，12点0分、11点30分、10点15分
@property(nonatomic, strong) NSArray<HwTimePoint *> *times;

@property(nonatomic, assign) HwWeek week;
@property(nonatomic, assign) HwReminderVibrantType vibrantType;
@property(nonatomic, assign) HwVibrationState vib;
/**
 Custom Content will show on the watch's screen when there is a reminder.

 */
@property(nonatomic, copy) NSString *custom;
/**
 Remind me again after 'reminderLater' minutes
 Unit: minutes
 */
@property(nonatomic, assign) NSUInteger reminderLater;

+ (HwReminder *) reminderFromAlarm:(HwAlarm *)alarm;

@end

NS_ASSUME_NONNULL_END
