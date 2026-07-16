//
//  HwBluetoothTask.h
//  CocoaLumberjack
//
//  Created by sujiang on 2020/4/9.
//

#import <Foundation/Foundation.h>
#import "HwBluetoothError.h"
#import "HwBluetoothCallback.h"

@class HwBluetoothData, HwBluetoothDevice, HwBluetoothCenter;

FOUNDATION_EXPORT NSString *const HwBluetoothTaskCancelNotfication;
FOUNDATION_EXPORT NSString *const HwBluetoothTaskFinishExcutingNotfication;

typedef NS_ENUM(NSInteger, HwBluetoothTaskState)
{
    HwBluetoothTaskStateNew,
    HwBluetoothTaskStateExcuting,
    HwBluetoothTaskStateFailed,
    HwBluetoothTaskStateTimeout,
    HwBluetoothTaskStateSuccess,
    HwBluetoothTaskStateCancel
};

typedef NS_ENUM(NSInteger, HwBluetoothTaskType)
{
    HwBluetoothTaskTypeData,
    HwBluetoothTaskTypeResponse,
    HwBluetoothTaskTypeAddressBook
};

typedef NS_ENUM(NSInteger, HwBluetoothTaskPriority)
{
    HwBluetoothTaskPriorityLow = 250,
    HwBluetoothTaskPriorityDefault = 500,
    HwBluetoothTaskTypePriorityHight = 750,
    HwBluetoothTaskTypePriorityTop = 1000,
};

@class HwBluetoothTask;
@protocol HwBluetoothTaskDelegate<NSObject>

- (void) taskFailedAndRequestRetry:(HwBluetoothTask *)task;

@end

@interface HwBluetoothTask : NSObject

// 这里可以覆盖dataModel的timeout
@property(nonatomic, assign) NSTimeInterval timeout;
@property(nonatomic, assign) NSTimeInterval lastUpdateTime;
@property(nonatomic, assign) HwBluetoothTaskType type;
@property(nonatomic, weak) id<HwBluetoothTaskDelegate> delegate;
@property(nonatomic, assign) HwBluetoothTaskState state;
@property(nonatomic, assign) HwBluetoothTaskPriority priority;
@property(nonatomic, strong) NSError *error;

@property(nonatomic, strong) HwBluetoothData *dataModel;
@property(nonatomic, strong) HwBluetoothDevice *sendDevice;
@property(nonatomic, copy) HwBCRequestCallback callback;

- (HwBluetoothTask *) initWithDataModel:(HwBluetoothData *)dataModel
                             sendDevice:(HwBluetoothDevice *)sendDevice
                               callback:(HwBCRequestCallback)callback;

/**
 这个不需要自己调用的，框架调用
 */
- (void) start;


/**
 这个可以自己调用取消任务
 */
- (void) cancel;

- (BOOL) isTimeout;

@end
