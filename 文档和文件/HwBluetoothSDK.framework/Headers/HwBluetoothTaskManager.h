//
//  HwBluetoothTaskManager.h
//  HwBluetooth
//
//  Created by SuJiang on 2018/4/15.
//  Copyright © 2021年 huawo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HwBluetoothCallback.h"
#import "HwBluetoothTask.h"

#pragma mark - task manager

@protocol HwBluetoothTaskManagerDelegate <NSObject>

- (void) taskManagerRequestReconnect;

@end


@interface HwBluetoothTaskManager : NSObject

@property(nonatomic, weak) id<HwBluetoothTaskManagerDelegate> delegate;

- (void) clean;

- (void) addTask:(HwBluetoothTask *)task;
- (void) beginTask;

- (void) removeTask:(HwBluetoothTask *)task;
- (void) removeAllTask;
- (void) removeAllTaskOfType:(HwBluetoothTaskType)type;
- (void) removeTaskByCMD:(Byte)cmd;
- (void) removeTaskBySendData:(NSData *)sendData;

- (void) updateSendDevice:(HwBluetoothDevice *)device;

- (void) handBlePowerOff;

/**
 获取任务列表
 
 @return 任务列表
 */
- (NSArray *) getDataTaskList;
- (NSArray *) getResponseTaskList;

#pragma mark - 错误码处理
- (void) setHandler:(HwTaskErrorHandler)handler
       forErrorCode:(NSUInteger)errorCode;
- (void) clearErrorCodeHandlers;


@end
