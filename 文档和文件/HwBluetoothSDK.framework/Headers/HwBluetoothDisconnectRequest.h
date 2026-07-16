//
//  HwBluetoothDisconnectRequest.h
//  AFNetworking
//
//  Created by HuaWo on 2022/8/21.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "HwBluetoothTimer.h"
#import "HwBluetoothCallback.h"

NS_ASSUME_NONNULL_BEGIN

@class HwBluetoothDisconnectRequest;
@protocol HwBluetoothDisconnectRequestDelegate <NSObject>

- (void) disconnectRequestDone:(HwBluetoothDisconnectRequest *_Nonnull)request
                         error:(NSError *_Nullable)error;

@end

@interface HwBluetoothDisconnectRequest : HwBluetoothTimer

@property(nonatomic, weak) id<HwBluetoothDisconnectRequestDelegate> delegate;
@property(nonatomic, strong) HwBluetoothDevice *device;
@property(nonatomic, copy) HwConnectCallback callback;

- (HwBluetoothDisconnectRequest *) initWithDevice:(HwBluetoothDevice *)device
                                          timeout:(NSTimeInterval)timeout
                                         callback:(HwConnectCallback)callback;

- (void) didDisconnectPeripheral:(CBPeripheral *)peripheral;

@end

NS_ASSUME_NONNULL_END
