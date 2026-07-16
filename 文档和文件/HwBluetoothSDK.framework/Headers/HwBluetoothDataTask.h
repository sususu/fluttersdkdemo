//
//  HwBluetoothDataTask.h
//  CocoaLumberjack
//
//  Created by sujiang on 2020/4/9.
//

#import "HwBluetoothTaskManager.h"

@interface HwBluetoothDataTask : HwBluetoothTask

+ (HwBluetoothDataTask *)taskWithDataModel:(HwBluetoothData *)dataModel
                                sendDevice:(HwBluetoothDevice *)sendDevice
                                  callback:(HwBCRequestCallback)callback;

- (HwBluetoothDataTask *) initWithDataModel:(HwBluetoothData *)dataModel
                                 sendDevice:(HwBluetoothDevice *)sendDevice
                                   callback:(HwBCRequestCallback)callback;

- (void) restartTimerIfNeeded;

@end

