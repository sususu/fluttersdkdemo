//
//  HwPrayerBeadsSwitch.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2024/10/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HwPrayerBeadsInteractiveType) {
    HwPrayerBeadsInteractiveTypeVibrate = 0,
    HwPrayerBeadsInteractiveTypeVibrateAndRing = 1,
    HwPrayerBeadsInteractiveTypeNone = 2
};

@interface HwPrayerBeadsSwitch : NSObject

@property(nonatomic, assign, getter=isOn) BOOL on;
@property(nonatomic, assign) NSTimeInterval interval;
@property(nonatomic, assign) NSInteger startHour;
@property(nonatomic, assign) NSInteger startMinute;
@property(nonatomic, assign) NSInteger endHour;
@property(nonatomic, assign) NSInteger endMinute;
@property(nonatomic, assign) NSInteger weekDays;
@property(nonatomic, assign) HwPrayerBeadsInteractiveType interactiveType;


@end

NS_ASSUME_NONNULL_END
