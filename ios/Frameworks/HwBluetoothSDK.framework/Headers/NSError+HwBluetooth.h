//
//  NSError+HwBluetooth.h
//  HwBluetooth
//
//  Created by SuJiang on 2018/4/21.
//  Copyright © 2021年 huawo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HwBluetoothError.h"

@interface NSError (HwBluetooth)

+ (NSError *) paramsError;
+ (NSError *) dataFormatError;
+ (NSError *) disconnectError;
+ (NSError *) connectTimeoutError;
+ (NSError *) unsuportDeviceError;
+ (NSError *) deviceErrorWithCode:(NSInteger)code;
+ (NSError *) taskCanelError;
+ (NSError *) powerOffError;

@end
