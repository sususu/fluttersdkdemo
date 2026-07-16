//
//  HwHeartrateFatigues.h
//  Pods
//
//  Created by HuaWo on 2022/6/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Stress and SpO2 data model:
 As the firmware combines heart rate variability, pressure and blood oxygen data into one protocol, this data model defines three values, as shown in the following attribute description.
 */
@interface HwHeartrateFatigue : NSObject
/**
 This value cannot be used as a unique identifier for data.
 It is only useful for logging and debug.
 */
@property(nonatomic, assign) NSInteger hIndex;
/**
 The time of data generation.
 Please note that it is different from other health data models. The unit of this value is milliseconds.
 */
@property(nonatomic, assign) long time;
/**
 Not available
 */
@property(nonatomic, assign) NSInteger fatigue;
/**
 Pressure value. When this value is not 0, it means that this data is stress data.
 In an instance object, only one of the three(fatigue/stress/bloodOxygen) values is not 0.
 */
@property(nonatomic, assign) NSInteger stress;
/**
 Pressure value. When this value is not 0, it means that this data is SpO2 data.
 In an instance object, only one of the three(fatigue/stress/bloodOxygen) values is not 0.
 */
@property(nonatomic, assign) NSInteger bloodOxygen;

@end

NS_ASSUME_NONNULL_END
