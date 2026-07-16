//
//  HwScheduleReminder.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2022/2/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwScheduleReminder : NSObject

@property(nonatomic, strong) NSString *remindContent;
@property(nonatomic, assign) NSInteger year;
@property(nonatomic, assign) NSInteger month;
@property(nonatomic, assign) NSInteger day;
@property(nonatomic, assign) NSInteger hour;
@property(nonatomic, assign) NSInteger min;
@property(nonatomic, assign) NSInteger second;
@property(nonatomic, assign) NSInteger remindMinutes;
@property(nonatomic, strong) NSString *address;

@end

NS_ASSUME_NONNULL_END
