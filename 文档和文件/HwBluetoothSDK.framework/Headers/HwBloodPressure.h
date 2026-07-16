//
//  HwBloodPressure.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2022/9/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwBloodPressure : NSObject

@property(nonatomic, assign) NSUInteger index;
@property(nonatomic, assign) NSTimeInterval time;
@property(nonatomic, assign) NSInteger systolic;
@property(nonatomic, assign) NSInteger diastolic;

@end

NS_ASSUME_NONNULL_END
