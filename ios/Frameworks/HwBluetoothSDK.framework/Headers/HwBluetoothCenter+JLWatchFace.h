//
//  HwBluetoothCenter+JLWatchFace.h
//  HwBluetoothSDK
//
//  Created by kingwear on 2026/2/11.
//

#import "HwBluetoothCenter.h"
#import "HwJLWatchFaceConfigModel.h"

@interface HwBluetoothCenter (JLWatchFace)

- (void)updateJLCustomWatceFace:(HwJLWatchFaceConfigModel *)configModel
                       callback:(HwBoolCallback _Nullable)callback;

@end

