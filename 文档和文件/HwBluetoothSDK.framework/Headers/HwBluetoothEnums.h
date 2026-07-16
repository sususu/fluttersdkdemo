//
//  HwBluetoothEnums.h
//  Pods-HwBluetoothSDK_Example
//
//  Created by HuaWo on 2022/6/13.
//

#ifndef HwBluetoothEnums_h
#define HwBluetoothEnums_h

#import <Foundation/Foundation.h>
#pragma mark - enum

/*!
 phone Bluetooth state
 
 - HwBluetoothStateDisable: Bluetooth is closed
 - HwBluetoothStateUnauthorized: User not authorized
 - HwBluetoothStateAvailable: Good
 */
typedef NS_ENUM(NSInteger, HwBluetoothState) {
    HwBluetoothStateDisable,
    HwBluetoothStateUnauthorized,
    HwBluetoothStateAvailable
};

/*!
 连接状态
 
 - HwBluetoothConnectionStateDisconnected: 断链了
 - HwBluetoothConnectionStateConnecting: 连接中
 - HwBluetoothConnectionStateConnected: 已连接
 
 */
typedef NS_ENUM(NSInteger, HwBluetoothConnectionState) {
    HwBluetoothConnectionStateConnecting = 1,
    HwBluetoothConnectionStateDisconnected,
    HwBluetoothConnectionStateConnected
};


#endif /* HwBluetoothEnums_h */
