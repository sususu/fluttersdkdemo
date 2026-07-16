//
//  HwBluetoothCenter+FileDifferenceOta.h
//  HwBluetoothSDK
//
//  Created by kingwear on 2025/8/29.
//

#import "HwBluetoothCenter.h"

// 日志回调block类型定义
typedef void(^FdOtaLogBlock)(NSString *logMessage);

@interface HwBluetoothCenter (FileDifferenceOta)

- (void)fdOtaStartWithFileData:(NSData *)fileData
                 readyCallback:(HwBoolCallback)readyCallback
              progressCallback:(HwBCFloatCallback)progressCallback
                finishCallback:(HwBoolCallback)finishCallback;

- (void)setFdOtaLogBlock:(FdOtaLogBlock)logBlock;

- (void)setUseFixedErrorCrc:(BOOL)enabled;

@end
