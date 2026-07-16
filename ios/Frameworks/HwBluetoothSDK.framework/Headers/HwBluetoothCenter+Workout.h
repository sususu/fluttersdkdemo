//
//  HwBluetoothCenter+Workout.h
//  CocoaLumberjack
//
//  Created by sujiang on 2020/8/14.
//

#import "HwBluetoothCenter.h"
#import "HwWorkoutPoint.h"
#import "HwWorkoutGpsPoint.h"
#import "HwWorkout.h"
#import "HwWorkoutRealtimeData.h"

typedef void (^HwWorkoutCountCallback)(NSUInteger count, NSError *_Nullable error);
typedef void (^HwWorkoutCountForLSCallback)(NSUInteger workoutCount, NSUInteger detailCount, NSError *_Nullable error);
typedef void (^HwWorkoutsCallback)(NSArray<HwWorkout *> * _Nullable workouts, NSError * _Nullable error);
typedef void (^HwWorkoutPointsCallback)(NSArray<HwWorkoutPoint *> * _Nullable workoutPoints, NSArray<HwWorkoutGpsPoint *> * _Nullable workoutGpsPoints,NSError * _Nullable error);
typedef void (^HwWorkoutRealtimeDataCallback)(HwWorkoutRealtimeData * _Nullable realtimeData, NSError * _Nullable error);

@interface HwBluetoothCenter (Workout)


/*! @brief
 获取设备中的运动记录个数[gain the sport record number of the device]
 
 @param callback 运动记录个数回调[sport record number callback]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) getWorkoutCountWithCallback:(HwWorkoutCountCallback _Nullable )callback;

- (HwBluetoothTask *_Nullable) getWorkoutNumForLSWithStartTime:(NSTimeInterval)startTime
                                                       endTime:(NSTimeInterval)endTime
                                                      callback:(HwWorkoutCountForLSCallback _Nullable)callback;
/*! @brief
 获取设备是否正在锻炼的状态，1 表示正在锻炼，0表示不在锻炼
 */
- (HwBluetoothTask *_Nullable) getWorkoutStateWithCallback:(HwBCIntegerCallback _Nonnull)callback;
- (HwBluetoothTask *_Nullable) getWorkoutsWithStartTime:(NSTimeInterval)startTime
                                                endTime:(NSTimeInterval)endTime
                                                  count:(NSInteger)count
                                               callback:(HwWorkoutsCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getWorkoutPointsWithStartTime:(NSTimeInterval)startTime
                                                     endTime:(NSTimeInterval)endTime
                                                       count:(NSInteger)count
                                                    callback:(HwWorkoutPointsCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) getWorkoutsWithCount:(NSUInteger)count callback:(HwWorkoutsCallback _Nullable)callback;

/*! @brief
 运动记录信息[sport record]
 
 @param callback 运动记录回调[HwWorkoutPoint callback]
 */
- (void) getWorkoutPointsWithCallback:(HwWorkoutPointsCallback _Nullable)callback;


/*! @brief
 删除运动记录[delete sport record]
 
 @param callback 回调[call back]
 @return 任务[task]
 */
- (HwBluetoothTask *_Nullable) deleteWorkoutWithCallback:(HwBoolCallback _Nullable )callback;

- (HwBluetoothTask *_Nullable) setWorkoutRealtimeData:(HwWorkoutRealtimeData *_Nonnull)realtimeData callback:(HwBoolCallback _Nullable )callback;

- (HwBluetoothTask *_Nullable) setWorkoutAction:(HwWorkoutAction)action
                                           type:(int)type
                             dataUpdateInterval:(NSInteger)dataUpdateInterval
                                       callback:(HwBoolCallback _Nullable )callback;

- (HwBluetoothTask *_Nullable) setWorkoutAction:(HwWorkoutAction)action
                                           type:(int)type
                                       goalType:(NSInteger)goalType
                                        goalVal:(NSInteger)goalVal
                             dataUpdateInterval:(NSInteger)dataUpdateInterval
                                       callback:(HwBoolCallback _Nullable )callback;

- (HwBluetoothTask *_Nullable) setWorkoutAction:(HwWorkoutAction)action
                                           type:(int)type
                                      goalTypes:(NSArray<NSNumber *> * _Nonnull)goalTypes
                                     goalValues:(NSArray<NSNumber *> * _Nonnull)goalVals
                             dataUpdateInterval:(NSInteger)dataUpdateInterval
                                       callback:(HwBoolCallback _Nullable )callback;


- (HwBluetoothTask *_Nullable) getWorkoutRealtimeDataWithCallback:(HwWorkoutRealtimeDataCallback _Nonnull)callback;

//设置当前GPS定位数据
- (HwBluetoothTask *_Nullable) setDeviceGpsLocationWithLongitude:(double)longitude
                                                        latitude:(double)latitude
                                                            time:(long)time
                                               callback:(HwBoolCallback _Nullable )callback;
- (HwBluetoothTask *_Nullable) setDeviceNonPreciseGpsLocationWithLongitude:(double)longitude
                                                                  latitude:(double)latitude
                                                                      time:(long)time
                                                                  callback:(HwBoolCallback _Nullable )callback;

@end

