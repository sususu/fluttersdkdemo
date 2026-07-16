//
//  HwMuslimDayAlert.h
//  HwBluetoothSDK
//
//  Created by kingwear on 2025/9/27.
//

#import <Foundation/Foundation.h>
#import "HwMuslimWorshipAlertTime.h"

NS_ASSUME_NONNULL_BEGIN

@interface HwMuslimDayAlert : NSObject

@property(nonatomic, assign) int dayFlag; // 提醒天数设置：0当前，-1前一天，1第二天，...
@property(nonatomic, strong) NSArray<HwMuslimWorshipAlertTime *> *worshipAlertTimeArr;

@end

NS_ASSUME_NONNULL_END
