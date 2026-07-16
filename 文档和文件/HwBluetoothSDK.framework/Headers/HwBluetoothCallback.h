//
//  HwBluetoothCallback.h
//  HwBluetooth
//
//  Created by SuJiang on 2018/4/12.
//  Copyright © 2021年 huawo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HwCommonDefines.h"


@interface HwBluetoothCallback : NSObject

@property(nonatomic, copy) HwSearchDevicesCallback searchDevicesCallback;
@property(nonatomic, copy) HwStopSearchingDevicesCallback stopSearchingDevicesCallback;
@property(nonatomic, copy) HwConnectCallback connectDeviceCallback;
@property(nonatomic, strong) NSMutableArray *connectDeviceCallbacks;
@property(nonatomic, copy) HwConnectCallback disconnectDeviceCallback;

@property(nonatomic, copy) HwDeviceRWReadyCallback bdReadyBlock;

- (void) clearAllCallbacks;

@end
