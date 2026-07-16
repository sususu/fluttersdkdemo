//
//  HwLS16.h
//  Pods
//
//  Created by HuaWo on 2022/8/3.
//

#import <Foundation/Foundation.h>
#import "HwWorkout.h"

NS_ASSUME_NONNULL_BEGIN

@interface HwLS16 : NSObject

- (NSInteger) workoutValueFromType:(HwWorkoutType)type
                     forDeviceType:(NSString *_Nullable)deviceType;
- (HwWorkoutType) workoutTypeFromValue:(NSInteger)value
                         forDeviceType:(NSString *_Nullable)deviceType;

@end

NS_ASSUME_NONNULL_END
