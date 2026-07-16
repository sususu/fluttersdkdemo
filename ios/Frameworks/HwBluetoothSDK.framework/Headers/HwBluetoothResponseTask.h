//
//  HwBluetoothResponseTask.h
//  CocoaLumberjack
//
//  Created by sujiang on 2020/4/9.
//

#import "HwBluetoothTaskManager.h"


@interface HwBluetoothResponseTask : HwBluetoothTask

+ (HwBluetoothResponseTask *)taskWithDataModel:(HwBluetoothData *)dataModel
                                    sendDevice:(HwBluetoothDevice *)sendDevice
                                      callback:(HwBCRequestCallback)callback;

- (HwBluetoothResponseTask *) initWithDataModel:(HwBluetoothData *)dataModel
                                     sendDevice:(HwBluetoothDevice *)sendDevice
                                       callback:(HwBCRequestCallback)callback;

@end


