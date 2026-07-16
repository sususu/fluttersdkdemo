//
//  HwBodyState.h
//  Pods
//
//  Created by HuaWo on 2024/9/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HwWorkout;
@interface HwBodyState : NSObject

@property(nonatomic, assign) NSTimeInterval recoveryTime;
@property(nonatomic, assign) HwWorkout *lastWorkout;
@end

NS_ASSUME_NONNULL_END
