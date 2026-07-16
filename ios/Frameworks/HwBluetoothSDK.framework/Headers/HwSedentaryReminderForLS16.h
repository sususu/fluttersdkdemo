//
//  HwSedentaryReminderForLS16.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2022/7/18.
//

#import <Foundation/Foundation.h>
#import "HwTimePoint.h"

NS_ASSUME_NONNULL_BEGIN

@interface HwSedentaryReminderForLS16 : NSObject

@property(nonatomic, assign) BOOL on;
@property(nonatomic, strong) HwTimePoint *startTime;
@property(nonatomic, strong) HwTimePoint *endTime;
@property(nonatomic, assign) NSInteger interval;
@property(nonatomic, assign) BOOL invalidTimeIntervalOn;
@property(nonatomic, strong) HwTimePoint *invalidStartTime;
@property(nonatomic, strong) HwTimePoint *invalidEndTime;

- (id) initWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
