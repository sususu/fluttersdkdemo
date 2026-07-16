//
//  HwStandingSetting.h
//  HwBluetoothSDK
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwStandingSetting : NSObject

@property(nonatomic, assign) BOOL reminderEnabled;
@property(nonatomic, assign) NSInteger goalHours;
@property(nonatomic, assign) NSInteger todayGoalHours;

+ (instancetype)settingFromData:(NSData *)data;

- (NSData *)toData;

@end

NS_ASSUME_NONNULL_END
