//
//  HwBluetoothConnectRequest.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2022/8/21.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "HwBluetoothTimer.h"
#import "HwBluetoothCallback.h"

NS_ASSUME_NONNULL_BEGIN
@class HwBluetoothDevice;
@class HwBluetoothConnectRequest;

@protocol HwBluetoothConnectionDelegate <NSObject>

- (void) connectRequestDone:(HwBluetoothConnectRequest *)request
                      error:(NSError *)error;

@end

@interface HwBluetoothConnectRequest : HwBluetoothTimer
@property(nonatomic, weak) id<HwBluetoothConnectionDelegate> delegate;
@property(nonatomic, strong) HwBluetoothDevice *device;
@property(nonatomic, copy) HwConnectCallback callback;
@property(nonatomic, assign, readonly) BOOL gettingReady;

- (HwBluetoothConnectRequest *) initWithDevice:(HwBluetoothDevice *)device
                                          timeout:(NSTimeInterval)timeout
                                         callback:(HwConnectCallback)callback;

- (BOOL) ifTheSamePeripheral:(CBPeripheral *)peripheral;
- (void) connectError:(NSError *)error;
- (void) didUpdateDeviceWithPeripheral:(CBPeripheral *)peripheral
                                  rssi:(NSNumber *)rssi
                     advertisementData:(NSDictionary<NSString *, id> *)advertisementData;
- (void) didConnectPeripheral:(CBPeripheral *)peripheral;

- (void) connectError:(NSError *)error;
- (void) connectSuccess;

- (void) start;

@end

NS_ASSUME_NONNULL_END
