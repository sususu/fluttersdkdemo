//
//  HwWorkoutRealtimeData.h
//  Pods
//
//  Created by HuaWo on 2022/7/21.
//

#import <Foundation/Foundation.h>
#import "HwWorkout.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HwWorkoutState) {
    HwWorkoutStateNone = 0x00,
    HwWorkoutStateStarted = 0x01,
    HwWorkoutStateSuspended = 0x02,
    HwWorkoutStateStopped = 0x03,
    HwWorkoutStateResumed = 0x04,
    HwWorkoutStateDataUpdated = 0x05
};

typedef NS_ENUM(NSInteger, HwWorkoutAction) {
    HwWorkoutActionNone = 0x00,
    HwWorkoutActionStart = 0x01,
    HwWorkoutActionSuspend = 0x02,
    HwWorkoutActionStop = 0x03,
    HwWorkoutActionResume = 0x04,
};

/**
 Workout realtime data
 */
@interface HwWorkoutRealtimeData : NSObject

/**
 millisecond
 */
@property(nonatomic, assign) long time;
@property(nonatomic, assign) HwWorkoutState state;
@property(nonatomic, assign) HwWorkoutType type;
/**
 step
 */
@property(nonatomic, assign) NSInteger step;
/**
 cal
 */
@property(nonatomic, assign) NSInteger calories;
/**
 meter
 */
@property(nonatomic, assign) NSInteger distance;
/**
 seconds
 */
@property(nonatomic, assign) NSInteger duration;
/**
 second/km
 */
@property(nonatomic, assign) NSInteger pace;
/**
 0.01 km/hour
 */
@property(nonatomic, assign) NSInteger speed;
/**
 How many seconds does a lap take.
 This property of the current watch has no value.
 */
@property(nonatomic, assign) NSInteger lapDuration;
/**
 Heartrate
 */
@property(nonatomic, assign) NSInteger bpm;
/**
 alert value
 */
@property(nonatomic, assign) NSInteger alertBpm;
@property(nonatomic, assign) NSInteger poolLength;
/**
 Whether bpm alert is on
 */
@property(nonatomic, assign) BOOL bpmAlertOn;

@property (assign, nonatomic) double longtitude;
@property (assign, nonatomic) double latitude;
@property (assign, nonatomic) double gpsSpeed;
@property (assign, nonatomic) float accuracy;
@property (assign, nonatomic) double altitude;
@property (assign, nonatomic) bool suspended;
@property (assign, nonatomic) bool turnBack;

@property (assign, nonatomic) NSUInteger laps;
@property (assign, nonatomic) NSUInteger actionCount;
@property (assign, nonatomic) NSUInteger consecutiveActionCount;
@property (assign, nonatomic) NSUInteger interruptActionCount;
/**
 * 次/分
 */
@property (assign, nonatomic) NSUInteger actionRate;
/**
 * 动作姿势
 */
@property (assign, nonatomic) NSUInteger actionPosture;
@property (assign, nonatomic) NSUInteger swolf;
@property (assign, nonatomic) NSUInteger actualDuration1;
@property (assign, nonatomic) NSUInteger actualDuration2;
@property (assign, nonatomic) NSUInteger actualDuration3;
@property (assign, nonatomic) NSInteger elevation;
@property (assign, nonatomic) NSInteger elevationGain;
@property (assign, nonatomic) NSInteger elevationLoss;
@property (assign, nonatomic) NSUInteger strike;
@property (assign, nonatomic) NSUInteger cadence;
@property (assign, nonatomic) NSInteger pressure;

- (id) initWithDuration:(NSInteger)duration
               distance:(NSInteger)distance
                  speed:(NSInteger)speed;

- (id) initWithData:(NSData *)data;

- (NSData *) toBytes;

@end

NS_ASSUME_NONNULL_END
