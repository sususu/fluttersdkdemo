//
//  HwBluetoothConnectionInfo.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2022/8/21.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HwBluetoothConnectMethod) {
    HwBluetoothConnectMethodPeripheral = 0x00,
    HwBluetoothConnectMethodMac = 0x01,
    HwBluetoothConnectMethodName = 0x02
};

@interface HwBluetoothConnectionInfo : NSObject

@property(nonatomic, strong) CBPeripheral *peripheral;
@property(nonatomic, assign) HwBluetoothConnectMethod method;

@end

NS_ASSUME_NONNULL_END
