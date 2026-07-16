//
//  HwWorkoutGpsPoint.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2024/5/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwWorkoutGpsPoint : NSObject

/**
 millisecond
 */
@property (assign, nonatomic) long time;
@property (assign, nonatomic) long offsetTime;
@property (assign, nonatomic, getter=isValid) bool valid;
@property (assign, nonatomic) double longtitude;
@property (assign, nonatomic) double latitude;
@property (assign, nonatomic) double speed;
@property (assign, nonatomic) float accuracy;
@property (assign, nonatomic) double altitude;
@property (assign, nonatomic) bool suspended;
@property (assign, nonatomic) bool turnBack;

@end

NS_ASSUME_NONNULL_END
