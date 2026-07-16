//
//  HwHandwashingConfig.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2021/6/18.
//

#import <Foundation/Foundation.h>
#import "HwBluetoothCenter+StatusSetting.h"

NS_ASSUME_NONNULL_BEGIN

@interface HwHandwashingConfig : NSObject

// remind switch
@property(nonatomic, assign) BOOL eventOn;

//start time to remind in a day
@property(nonatomic, assign) int startHour;
@property(nonatomic, assign) int startMinute;

// end time for reminding in a day
@property(nonatomic, assign) int endHour;
@property(nonatomic, assign) int endMinute;

// how often to remind (second)
@property(nonatomic, assign) int timeInterval;

// duration for once remind (second), such as 'Vibration duration'
@property(nonatomic, assign) int duration;

@property(nonatomic, assign) HwWeek week;

@end

NS_ASSUME_NONNULL_END
