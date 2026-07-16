//
//  HwLocalizeTimeZone.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2021/6/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HwTimeZone;
@interface HwLocalizeTimeZone : NSObject

@property (strong, nonatomic) HwTimeZone *timeZone;

@property (unsafe_unretained, nonatomic) int index;

@end

NS_ASSUME_NONNULL_END
