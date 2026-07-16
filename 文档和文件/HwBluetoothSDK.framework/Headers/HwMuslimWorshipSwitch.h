//
//  HwMuslimWorshipSwitch.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2024/10/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HwMuslimWorshipType) {
    HwMuslimWorshipTypeFajr = 1,
    HwMuslimWorshipTypeSunrise = 2,
    HwMuslimWorshipTypeDhuhr = 4,
    HwMuslimWorshipTypeAsr = 8,
    HwMuslimWorshipTypeSunset = 16,
    HwMuslimWorshipTypeMaghrib = 32,
    HwMuslimWorshipTypeIsha = 64
};

@interface HwMuslimWorshipSwitch : NSObject

@property(nonatomic, assign) HwMuslimWorshipType type;
@property(nonatomic, assign, getter=isOn) BOOL on;

- (HwMuslimWorshipSwitch *) initWithType:(HwMuslimWorshipType)type
                                      on:(BOOL)on;

@end

NS_ASSUME_NONNULL_END
