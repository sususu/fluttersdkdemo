//
//  HwSedentaryReminder.h
//  Pods
//
//  Created by HuaWo on 2022/6/15.
//

#import <Foundation/Foundation.h>
#import "HwTimePoint.h"
#import "HwDeviceDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface HwSedentaryReminder : NSObject

@property(nonatomic, assign) BOOL on;
@property(nonatomic, strong) HwTimePoint *startTime;
@property(nonatomic, strong) HwTimePoint *endTime;
@property(nonatomic, assign) NSInteger interval;
@property(nonatomic, assign) HwWeek week;

@end

NS_ASSUME_NONNULL_END
