//
//  HwBluetoothCenter+StandingSetting.h
//  HwBluetoothSDK
//

#import "HwBluetoothCenter.h"
#import "HwStandingSetting.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^HwStandingSettingCallback)(HwStandingSetting *_Nullable setting, NSError *_Nullable error);

@interface HwBluetoothCenter (StandingSetting)

- (HwBluetoothTask *)getStandingSettingWithCallback:(HwStandingSettingCallback)callback;
- (HwBluetoothTask *)setStandingSetting:(HwStandingSetting *)setting callback:(HwBoolCallback)callback;

@end

NS_ASSUME_NONNULL_END
