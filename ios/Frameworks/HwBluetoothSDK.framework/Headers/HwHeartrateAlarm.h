//
//  HwHeartrateAlarm.h
//  Pods
//
//  Created by HuaWo on 2022/6/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 HwHeartrateAlarm config class
 */
@interface HwHeartrateAlarm : NSObject

/**
 Whether the watch heart rate alarm is on
 */
@property(nonatomic, assign) BOOL on;
/**
 f the watch heart rate alarm is turned on and the heart rate reaches the upper limit, the watch will give a reminder
 */
@property(nonatomic, assign) NSUInteger upperLimit;
/**
 f the watch heart rate alarm is turned on and the heart rate reaches the lower limit, the watch will give a reminder
 */
@property(nonatomic, assign) NSUInteger lowerLimit;

@end

NS_ASSUME_NONNULL_END
