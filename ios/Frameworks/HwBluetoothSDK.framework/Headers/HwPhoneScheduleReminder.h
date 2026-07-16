//
//  HwPhoneScheduleReminder.h
//  HwBluetoothSDK
//

#import <Foundation/Foundation.h>
#import "HwPhoneScheduleReminderUnit.h"

NS_ASSUME_NONNULL_BEGIN

@interface HwPhoneScheduleReminder : NSObject

@property(nonatomic, assign) NSInteger value;
@property(nonatomic, assign) HwPhoneScheduleReminderUnit unit;
@property(nonatomic, assign) NSInteger hour;
@property(nonatomic, assign) NSInteger minute;

- (instancetype)initWithValue:(NSInteger)value
                         unit:(HwPhoneScheduleReminderUnit)unit
                         hour:(NSInteger)hour
                       minute:(NSInteger)minute;

- (NSData *)toBytes;

@end

NS_ASSUME_NONNULL_END
