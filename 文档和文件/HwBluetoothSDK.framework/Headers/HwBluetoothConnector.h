//
//  HwBluetoothConnector.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2021/12/23.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "HwBluetoothConnectRequest.h"

NS_ASSUME_NONNULL_BEGIN
#pragma mark - HwBluetoothConnector
@class HwBluetoothDevice;
@class HwBluetoothConnector;

@protocol HwBluetoothConnectorDelegate <NSObject>

@required
/**
 连接上peripheral，和下面didConnectDevice的区别是，还没有去发现服务和Notify特征
 */
- (void) bluetoothConnector:(HwBluetoothConnector *)connector
       didConnectPeripheral:(HwBluetoothDevice *)device;

/**
 完全连接上，可以进行数据通讯了
 */
- (void) bluetoothConnector:(HwBluetoothConnector *)connector
           didConnectDevice:(HwBluetoothDevice *)device;

- (void) bluetoothConnector:(HwBluetoothConnector *)connector
        didDisconnectDevice:(HwBluetoothDevice *)device;

@end

@interface HwBluetoothConnector : NSObject

@property(nonatomic, assign, readonly, getter=isConnecting) BOOL connecting;
@property(nonatomic, strong, readonly) HwBluetoothDevice *connectedDevice;
@property(nonatomic, weak) id<HwBluetoothConnectorDelegate> delegate;

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error;
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error;
- (void)centralManagerDidUpdateState:(CBCentralManager *)central;

- (void) connect:(HwBluetoothDevice *)device
        callback:(HwConnectCallback)callback;

- (void) connect:(HwBluetoothDevice *)device
         timeout:(NSTimeInterval)timeout
        callback:(HwConnectCallback)callback;

- (void) disconnectWithTimeout:(NSTimeInterval)timeout
                      callback:(HwConnectCallback)callback;

@end

NS_ASSUME_NONNULL_END
