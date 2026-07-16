/*!
 @header HwBluetoothCenter.h
 
 @author sujiang on 2018/4/11.
 @copyright  2021年 huawo. All rights reserved.
 */
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "HwBluetoothCallback.h"
#import "HwBluetoothDevice.h"
#import "HwBluetoothError.h"
#import "HwBluetoothTaskManager.h"
#import "HwBluetoothConfig.h"
#import "HwBluetoothEnums.h"

@class HwBluetoothData;

static const NSTimeInterval kDefaultConnectTimeout = 20;
static const NSTimeInterval kDefaultScanTimeout = 5;
static const NSTimeInterval kDefaultDisconnectTimeout = 10;

#pragma mark - notification
// 蓝牙状态改变时通知

// 蓝牙打开通知 [ble turned on notification]
extern NSString *HwBluetoothStatePoweredOnNotification;
// 蓝牙状态不可知通知 [ble state unknown notification]
extern NSString *HwBluetoothStateUnknowNotification;
// 蓝牙状态重置ing通知 [ble state reset notification]
extern NSString *HwBluetoothStateResettingNotification;
extern NSString *HwBluetoothStateUnsupportedNotification;
extern NSString *HwBluetoothStateUnauthorizedNotification;
extern NSString *HwBluetoothStatePoweredOffNotification;
// 蓝牙状态改变通知
extern NSString *HwBluetoothStateChangedNotification;
extern NSString *HwBluetoothConnectionStateChangedNotification;

// 蓝牙设备正在自动连接的通知[ble is auto-connecting notification]
extern NSString *HwBluetoothStartAutoConnectingNotification;
// 蓝牙设备结束自动连接的通知[ble is end-connecting notification ]
extern NSString *HwBluetoothEndAutoConnectingNotification;
// 连接设备失败的通知[fail to connect with device notification]
extern NSString *HwBluetoothDidFailToConnectDeviceNotification;
// 设备已经连接上的通知[device connect with phone successfully notification]
extern NSString *HwBluetoothConnectedFromRestoreStateNotification;

extern NSString *HwBluetoothConnectedNotification;

#pragma mark - keys

extern NSString *HwKeyBluetoothConnectedDeviceName;
extern NSString *HwKeyBluetoothDeviceType;
extern NSString *HwKeyBluetoothDeviceID;
extern NSString *HwKeyBluetoothRestoreKey;

#pragma mark - class

/*!
 @class HwBluetoothCenter
 @classdesign 单例 [singleton]
 @brief 蓝牙管理中心 [ble management center]
 
 蓝牙SDK中心类，所有的功能入口中心 [ble management center class, All function entrance ]
 采用单例模式，请使用 [HwBluetoothCenter sharedInstance] 获取实例对象
 
 */
@interface HwBluetoothCenter : NSObject


/*!
 @brief 返回蓝牙管理中心单例 [return ble management center singleton]
 
 @return HwBluetoothCenter 实例
 */
+ (HwBluetoothCenter *)sharedInstance;


/**
 @brief 重新初始化ble management center singleton

 */
- (void) resetCenter;

#pragma mark - property
/*! @brief
 当前连接上的设备 [device name connected]
 */
@property(nonatomic, strong, readonly) HwBluetoothDevice *connectedDevice;

/*! @brief
 蓝牙状态 [ble state]
 */
@property(nonatomic, assign, readonly) HwBluetoothState state;

/*! @brief
 蓝牙连接状态 [ble connection state]
 */
@property(nonatomic, assign, readonly) HwBluetoothConnectionState connectionState;

@property(nonatomic, assign, readonly) BOOL connecting;


/**
 蓝牙中心 ble central manager
 */
@property(nonatomic, strong, readonly) CBCentralManager *manager;

@property(nonatomic, assign, readonly, getter=isOTAing) BOOL OTAing;

#pragma mark - public methods

/**
 @brief 蓝牙搜索设备 [search device]
 
 @param callback callback
 */
- (void) searchDevicesWithCallback:(HwSearchDevicesCallback)callback;

/*!
 @brief 停止搜索设备 [stop search device]
 */
- (void) stopSearchingDevices;
- (void) startSearchingDevices;

/*!
 @brief 蓝牙搜索设备，几秒之后自动停止搜索 [ble will search device, but it will stop after a few seconds]
 
 @param callback 每次搜索到设备都会回调 [there is a callback everytime ble searchs]
 @param second 多少秒之后自动停止搜索，如果是0，则不会自动停止 [after how many seconds auto-search should stop, if set 0, it will never stop]
 @param stopCallback 自动停止后，回调 [callback when stop search]
 */
- (void) searchDevicesWithCallback:(HwSearchDevicesCallback)callback
            autoStopSearchingAfter:(NSTimeInterval)second
                      stopCallback:(HwStopSearchingDevicesCallback)stopCallback;


- (void) scanDevicesForConnectWithCallback:(HwSearchDevicesForConnectionCallback)callback
                                   timeout:(NSTimeInterval)timeout
                              stopCallback:(HwStopSearchingDevicesForConnectionCallback)stopCallback;

- (NSArray<HwBluetoothDevice *> *) getPhoneConnectedDevices;

/*!
 @brief 连接设备 [connect device]
 @discussion 这里连接设备，应该是传入的搜索蓝牙设备接口搜索得到的设备。你也可以调用其他方法，只需要传入设备名称就可以进行连接 [regarding connect device , you should input device name searched by ble searching api(searchDevicesWithCallback) as parameter.You could also call other functions(connectDeviceName), what you need to do is just input device name, it should connect ]
 @see searchDevicesWithCallback:autoStopSearchingAfter:callback:
 @see connectDeviceName:callback:
 
 @param device 设备对象
 @param callback 回调
 */
- (void) connectDevice:(HwBluetoothDevice *)device callback:(HwConnectCallback)callback;

/*!
 @brief 连接设备
 
 @param device 设备对象
 @param second 超时时间
 @param callback 回调
 */
- (void) connectDevice:(HwBluetoothDevice *)device
               timeout:(NSTimeInterval)second
              callback:(HwConnectCallback)callback;

/*!
 @brief 根据名称连接设备 [connect device]
 
 @param deviceName 设备名称
 @param callback 回调
 */
- (void) connectDeviceName:(NSString *)deviceName callback:(HwConnectCallback)callback;

/*!
 @brief 根据设备名称连接设备
 
 @param deviceName 设备名称
 @param timeout 连接超时时间
 @param callback 回调
 */
- (void) connectDeviceName:(NSString *)deviceName timeout:(NSTimeInterval)timeout callback:(HwConnectCallback)callback;

- (void) connectMac:(NSString *)mac callback:(HwConnectCallback)callback;
- (void) connectMac:(NSString *)mac timeout:(NSTimeInterval)timeout callback:(HwConnectCallback)callback;

- (void) otaFinish;
- (void) otaFailed;
/*!
 @brief 断连设备 [disconnect with device]
 
 @param callback 回调
 */
- (void) disconnectWithCallback:(HwConnectCallback)callback;
- (void) disconnect;

/*!
 @brief 断连设备[disconnect with device]
 
 @param timeout 超时时间
 @param callback 回调
 */
- (void) disconnectWithTimeout:(NSTimeInterval)timeout callback:(HwConnectCallback)callback;

/*!
 @brief Get device connected last time
 */
- (HwBluetoothDevice *_Nullable) getLastConnectedDevice;

/*!
 @brief 清除连接设备信息 [clear up device connection info]
 */
- (void) clearConnectionInfo;


/*!
 @brief 取消所有的蓝牙任务 [canncel all ble task]
 */
- (void) clearAllBluetoothTasks;

- (NSInteger) bluetoothTaskCount;

/*!
 @brief 发送蓝牙请求，使用SDK时，优先级是Default
 
 @param dataModel 数据模型
 @param callback 回调
 @return 任务
 */
- (HwBluetoothTask *) sendRequest:(HwBluetoothData *)dataModel callback:(HwBCRequestCallback)callback;

/*!
@brief 发送蓝牙请求，使用SDK时，内部使用

@param dataModel 数据模型
@param priority 优先级
@param callback 回调
@return 任务
*/
- (HwBluetoothTask *) sendRequest:(HwBluetoothData *)dataModel priority:(HwBluetoothTaskPriority)priority callback:(HwBCRequestCallback)callback;

/*!
 @brief 手动停止当前任务，并指定发生什么错误
 一般不要自己去调用这个函数
 这个函数公开给蓝牙框架内部调用
 
 @param errorCode 错误码
 @see HwBCCodeBLEDisconnected
 @see HwBCCodeRequestTimeout
 @see HwBCCodeConnectTimeout
 */
- (void) stopCurrentTaskWithErrorCode:(HwBCCode)errorCode;

/**
 获取手机上已经连上的蓝牙设备
 
 @param serviceUUIDs 根据服务IDs
 @return 已经连接上的设备
 */
- (NSArray *_Nonnull) getPhoneConnectedDevices:(NSArray *_Nullable)serviceUUIDs;

- (void) updateMacAddressIfNeedWithMac:(NSString *_Nonnull)mac;
- (void) updateMacAddress:(NSString *_Nonnull)mac forPerpherialUUID:(NSString *)uuid;

#pragma mark - 错误码处理
- (void) setHandler:(void(^_Nonnull)(HwBluetoothData * _Nullable dataModel))handler
       forErrorCode:(HwBCCode)errorCode;
- (void) clearErrorCodeHandlers;

@end
