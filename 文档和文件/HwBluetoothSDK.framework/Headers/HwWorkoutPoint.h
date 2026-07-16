//
//  HwWorkoutPoint.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2022/1/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwWorkoutPoint : NSObject
/**
 millisecond
 */
@property (assign, nonatomic) long time;
@property (assign, nonatomic) long offsetTime;
/**
 step, -255 if none
 */
@property (assign, nonatomic) NSInteger step;
/**
 cal, -255 if none
 */
@property (assign, nonatomic) NSInteger calories;
/**
 meter, -255 if none
 */
@property (assign, nonatomic) NSInteger distance;
/**
 minutes, -255 if none
 */
@property (assign, nonatomic) NSInteger duration;
/**
 heartrate, -255 if none
 */
@property (assign, nonatomic) NSInteger bpm;
/**
 km/hour, -255 if none
 */
@property (assign, nonatomic) NSInteger speed;
/**
 second/km, -255 if none
 */
@property (assign, nonatomic) NSInteger pace;

@property(nonatomic, assign) NSInteger actionPosture;
@property(nonatomic, assign) NSInteger currentSwolf;
@property(nonatomic, assign) NSInteger actionCount;
@property(nonatomic, assign) NSInteger currentDuration;
@property(nonatomic, assign) NSInteger avgActionRate;
@property(nonatomic, assign) NSInteger maxActionRate;
@property(nonatomic, assign) NSInteger currentAvgPace;
@property(nonatomic, assign) NSInteger consecutiveActionCount;
/**
 1开始、2暂停、3继续、4结束
 */
@property(nonatomic, assign) NSInteger state;

- (BOOL) isSuspended;
- (BOOL) isSuspendedEnd;

@end

NS_ASSUME_NONNULL_END
