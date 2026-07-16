//
//  HwBluetoothScanner.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2022/8/19.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "HwBluetoothCallback.h"
#import "HwBluetoothTimer.h"

NS_ASSUME_NONNULL_BEGIN

@interface HwBluetoothScanRequest : HwBluetoothTimer

@property(nonatomic, copy) HwSearchDevicesCallback scanCallback;
@property(nonatomic, copy) HwSearchDevicesForConnectionCallback scanForConnectCallback;
@property(nonatomic, copy) HwStopSearchingDevicesForConnectionCallback stopScanForConnectCallback;
@property(nonatomic, copy) HwStopSearchingDevicesCallback stopCallback;

- (HwBluetoothScanRequest *) initWithCallback:(HwSearchDevicesCallback _Nonnull)callback
                                      timeout:(NSTimeInterval)timeout
                                 stopCallback:(HwStopSearchingDevicesCallback _Nullable)stopCallback;

- (HwBluetoothScanRequest *) initWithScanForConnectCallback:(HwSearchDevicesForConnectionCallback _Nonnull)callback timeout:(NSTimeInterval)timeout
stopCallback:(HwStopSearchingDevicesForConnectionCallback _Nonnull)stopCallback;

@end


@interface HwBluetoothScanner : NSObject

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI;
- (void)centralManagerDidUpdateState:(CBCentralManager *)central;

- (void) scanWithTimeout:(NSTimeInterval)timeout
                callback:(HwSearchDevicesCallback _Nonnull)callback
            stopCallback:(HwStopSearchingDevicesCallback _Nullable)stopCallback;

- (void) scanForConnectWithTimeout:(NSTimeInterval)timeout
                          callback:(HwSearchDevicesForConnectionCallback _Nonnull)callback
                      stopCallback:(HwStopSearchingDevicesForConnectionCallback _Nonnull)stopCallback;

- (void) stopScanManually;

@end

NS_ASSUME_NONNULL_END
