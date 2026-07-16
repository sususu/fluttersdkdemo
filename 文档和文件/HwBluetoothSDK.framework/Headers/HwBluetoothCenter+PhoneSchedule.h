//
//  HwBluetoothCenter+PhoneSchedule.h
//  HwBluetoothSDK
//

#import "HwBluetoothCenter.h"
#import "HwPhoneScheduleEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface HwBluetoothCenter (PhoneSchedule)

- (HwBluetoothTask *)syncPhoneSchedules:(NSArray<HwPhoneScheduleEvent *> *)events callback:(HwBoolCallback)callback;

@end

NS_ASSUME_NONNULL_END
