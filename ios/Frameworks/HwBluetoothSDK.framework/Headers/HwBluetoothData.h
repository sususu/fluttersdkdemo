//
//  HwBluetoothData.h
//  HwBluetooth
//
//  Created by SuJiang on 2018/4/12.
//  Copyright © 2021年 huawo. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 蓝牙信息交互通道
 
 - HwBluetoothDataChannel8001: 8001
 - HwBluetoothDataChannel8002: 8002
 - HwBluetoothDataChannel8003: 8003
 - HwBluetoothDataChannel8004: 8004
 */
typedef NS_ENUM(NSInteger, HwBluetoothDataChannel)
{
    HwBluetoothDataChannel8001,
    HwBluetoothDataChannel8002,
    HwBluetoothDataChannel8003,
    HwBluetoothDataChannel8004
};

typedef NS_ENUM(NSInteger, HwBluetoothDataState)
{
    HwBluetoothDataStatePlain,
    HwBluetoothDataStateSending,
    HwBluetoothDataStateSent,
    HwBluetoothDataStateSendFailed,
    HwBluetoothDataStateReciving,
    HwBluetoothDataStateRecived,
    HwBluetoothDataStateReciveFailed,
    HwBluetoothDataStateTimeout
};

@protocol HwBluetoothDataDelegate<NSObject>
// 需要刷新超时时间
- (void) bluetoothDataNeedRefreshTimeout;

@end


@interface HwBluetoothData : NSObject

@property(nonatomic, weak) id<HwBluetoothDataDelegate> delegate;

+ (HwBluetoothData *) dataWithSendData:(NSData *)sendData
                               timeout:(NSTimeInterval)timeout
                                  type:(HwBluetoothDataChannel)type;

+ (HwBluetoothData *) dataWithSendData:(NSData *)sendData
                                  type:(HwBluetoothDataChannel)type;

- (HwBluetoothData *) initWithSendData:(NSData *)sendData
                               timeout:(NSTimeInterval)timeout
                                  type:(HwBluetoothDataChannel)type;

- (HwBluetoothData *) initWithSendData:(NSData *)sendData
                                  type:(HwBluetoothDataChannel)type;

/**
 发送数据
 */
@property(nonatomic, strong) NSData *sendData;

/**
 超时时间，默认10s
 */
@property(nonatomic, assign) NSTimeInterval timeout;

/**
 数据类型
 */
@property(nonatomic, assign) HwBluetoothDataChannel type;

/**
 数据发送接收的状态
 */
@property(nonatomic, assign) HwBluetoothDataState state;

/**
 出错原因
 */
@property(nonatomic, strong) NSError *error;

/**
 取消发送标志
 */
@property(nonatomic, assign, getter=isCancelSend) BOOL cancelSend;

/**
 查询命令的数据，如果返回数据是1条，数据是datas；
 如果返回数据是2条或更多
 */
@property(nonatomic, strong) NSData *receiveData;
@property(nonatomic, strong) NSArray *receiveDatas;
@property(nonatomic, assign) NSUInteger receiveDataLength;
// 默认是只返回一条的
@property(nonatomic, assign) NSUInteger receiveDataCount;

/**
 设置命令的结果
 */
@property(nonatomic, assign) BOOL excuteCMDFlag;
@property(nonatomic, assign) NSInteger errorCode;

/**
 发送失败，重试次数，默认1次
 */
@property(nonatomic, assign) NSUInteger failedRetryCount;

- (void) refreshTimeout;

@end
