//
//  HwPhoneScheduleEvent.h
//  HwBluetoothSDK
//

#import <Foundation/Foundation.h>
#import "HwPhoneScheduleReminder.h"

NS_ASSUME_NONNULL_BEGIN

@interface HwPhoneScheduleEvent : NSObject

@property(nonatomic, assign) NSInteger eventId;
@property(nonatomic, assign) BOOL allDay;
@property(nonatomic, assign) NSInteger startYear;
@property(nonatomic, assign) NSInteger startMonth;
@property(nonatomic, assign) NSInteger startDay;
@property(nonatomic, assign) NSInteger startHour;
@property(nonatomic, assign) NSInteger startMinute;
@property(nonatomic, assign) NSInteger endYear;
@property(nonatomic, assign) NSInteger endMonth;
@property(nonatomic, assign) NSInteger endDay;
@property(nonatomic, assign) NSInteger endHour;
@property(nonatomic, assign) NSInteger endMinute;
@property(nonatomic, assign) BOOL reminderEnabled;
@property(nonatomic, copy, nullable) NSString *title;
@property(nonatomic, copy, nullable) NSString *notes;

+ (NSInteger)maxCount;

- (void)setReminders:(NSArray<HwPhoneScheduleReminder *> *)reminders;
- (NSArray<HwPhoneScheduleReminder *> *)reminders;
- (void)clearReminders;

- (NSArray *)toValueUnits;

@end

NS_ASSUME_NONNULL_END
