//
//  HwGoalValue.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2022/9/15.
//

#import <Foundation/Foundation.h>
#import "HwGoal.h"

NS_ASSUME_NONNULL_BEGIN

@interface HwGoalValue : NSObject

@property(nonatomic, assign) HwGoalType type;
@property(nonatomic, assign) NSInteger val;

@end

NS_ASSUME_NONNULL_END
