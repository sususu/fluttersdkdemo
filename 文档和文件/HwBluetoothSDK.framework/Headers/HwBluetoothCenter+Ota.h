//
//  HwBluetoothCenter+Ota.h
//  HwBluetooth
//
//  Created by SuJiang on 2018/4/8.
//  Copyright © 2021年 huawo. All rights reserved.
//

#import "HwBluetoothCenter.h"

typedef NS_ENUM(NSInteger, HwOtaType) {
    HwOtaTypePlatform = 1,
    HwOtaTypeTP,
    HwOtaTypeHeart,
    HwOtaTypePicture,
    HwOtaTypeFreeScale,
    HwOtaTypeAGPS,
    HwOtaTypePointer,
    HwOtaTypeWatchFace,
    HwOtaTypeWatchPatch = 0x0A, //RealTek平台使用,升级patch
    HwOtaTypeWatchFsbl = 0x0B //RealTek平台使用,升级fsbl
};

static const NSInteger kPackageCountCallback = 20;
static const NSInteger kSizeOfPieceData = 2048;

// 设备端每2K数据做一个存储、这边必须等设备存储完成之后才能继续发送数据，所以做数据分区
// 而且每次发送，发送20个字节，分区内，还要分包
@interface HwOtaDataSection : NSObject

// 包大小
@property(nonatomic, assign) NSInteger packageSize;
@property(nonatomic, strong) NSMutableArray *packageList;
// 当前发送到的索引
@property(nonatomic, assign) NSInteger currentPackageIndex;
@property(nonatomic, assign) NSInteger totalPackageCount;

@property(nonatomic, assign) NSInteger sectionSize;
@property(nonatomic, copy) NSData *sectionData;

@property(nonatomic, strong) NSTimer *otaTimer;

+ (HwOtaDataSection *) sectionWithData:(NSData *)data;

@end

@interface HwOtaDataModel : NSObject

@property(nonatomic, assign) HwOtaType type;
@property(nonatomic, copy) NSData *otaData;
@property(nonatomic, copy) NSData *otaAddressData;
@property(nonatomic, copy) NSData *otaCrcData;
@property(nonatomic, assign) NSUInteger otaLength;

// 分片区
@property(nonatomic, strong) NSMutableArray *sectionList;

+ (HwOtaDataModel *)dataModelWithType:(HwOtaType)type
                                 data:(NSData *)data;

- (void) cutDataToSections;
+ (NSData *)crcDataForData:(NSData *)sendData;

@end



@interface HwBluetoothCenter (Ota)<HwBluetoothDeviceDelegate>

@property(nonatomic, copy) HwBCFloatCallback progressCallback;
@property(nonatomic, copy) HwBoolCallback finishCallback;
// 总的数据长度
@property(nonatomic, assign) NSNumber *otaDataLength;
// 已发送的数据长度
@property(nonatomic, assign) NSNumber *otaSentLength;

@property(nonatomic, copy) NSMutableArray *dataModels;


- (void) getOtaStatusWithCallback:(HwBCOtaStatusCallback)callback;

/*!
 普通外设名称，这个接口会发指令给设备，让设备进入OTA模式
 在进入OTA模式之间，会检查电量等条件
 ota interface
 
 @param dataModels ota数据  ota file models
 @param otaDeviceName ota设备名称 ota device's name
 @param needResumeOta 是否需要断点续传 needResumeOta
 @param readyCallback 准好之后的回调 ota get ready callback
 @param progressCallback 进度回调 ota is processing
 @param finishCallback 完成的回调 ota finish(may fail)
 */
- (void) otaWithDataModels:(NSArray<HwOtaDataModel *> *)dataModels
             otaDeviceName:(NSString *)otaDeviceName
             needResumeOta:(BOOL)needResumeOta
             readyCallback:(HwBoolCallback)readyCallback
          progressCallback:(HwBCFloatCallback)progressCallback
            finishCallback:(HwBoolCallback)finishCallback;

/*!
 普通外设名称，这个接口会发指令给设备，让设备进入OTA模式
 在进入OTA模式之间
 
 @param dataModels ota数据
 @param otaDeviceName ota设备名称
 @param needJudgeBattery 是否需要判断电量大于30%
 @param readyCallback 准好之后的回调
 @param progressCallback 进度回调
 @param finishCallback 完成的回调
 */
- (void) otaWithDataModels:(NSArray<HwOtaDataModel *> *)dataModels
             otaDeviceName:(NSString *)otaDeviceName
             needResumeOta:(BOOL)needResumeOta
          needJudgeBattery:(BOOL)needJudgeBattery
             readyCallback:(HwBoolCallback)readyCallback
          progressCallback:(HwBCFloatCallback)progressCallback
            finishCallback:(HwBoolCallback)finishCallback;

- (void) otaWithDataModels:(NSArray<HwOtaDataModel *> *)dataModels
              batteryLimit:(NSInteger)batteryLimit
             readyCallback:(HwBoolCallback)readyCallback
          progressCallback:(HwBCFloatCallback)progressCallback
            finishCallback:(HwBoolCallback)finishCallback;

/*!
 普通外设名称，这个接口会发指令给设备，让设备进入OTA模式
 在进入OTA模式之间，会检查电量等条件
 
 @param dataModels ota数据
 @param otaDeviceName ota设备名称
 @param needJudgeBattery 是否需要判断电量大于30%
 @param connectTimeout 是否需要判断电量大于30%
 @param readyCallback 准好之后的回调
 @param progressCallback 进度回调
 @param finishCallback 完成的回调
 */
- (void) otaWithDataModels:(NSArray<HwOtaDataModel *> *)dataModels
             otaDeviceName:(NSString *)otaDeviceName
             needResumeOta:(BOOL)needResumeOta
          needJudgeBattery:(BOOL)needJudgeBattery
            connectTimeout:(NSTimeInterval)connectTimeout
             readyCallback:(HwBoolCallback)readyCallback
          progressCallback:(HwBCFloatCallback)progressCallback
            finishCallback:(HwBoolCallback)finishCallback;


/*!
 切换到OTA模式
 
 @param firmwareData 固件地址
 @param callback 回调
 */
- (void) otaUpgradeGetReadyWithData:(NSData *)firmwareData callback:(HwBoolCallback)callback;


/*!
 不检查任何条件，直接发指令进入ota模式
 
 @param dataModels ota数据
 @param otaDeviceName ota设备名称
 @param readyCallback 准好之后的回调
 @param progressCallback 进度回调
 @param finishCallback 完成的回调
 */
- (void) startOtaWithOtaDeviceName:(NSString *)otaDeviceName
                     needResumeOta:(BOOL)needResumeOta
                         otaModels:(NSArray<HwOtaDataModel *> *)dataModels
                     readyCallback:(HwBoolCallback)readyCallback
                  progressCallback:(HwBCFloatCallback)progressCallback
                    finishCallback:(HwBoolCallback)finishCallback;


/*!
 不检查任何条件，直接发指令进入ota模式
 
 @param dataModels ota数据
 @param otaDeviceName ota设备名称
 @param readyCallback 准好之后的回调
 @param progressCallback 进度回调
 @param finishCallback 完成的回调
 */
- (void) startOtaWithOtaDeviceName:(NSString *)otaDeviceName
                     needResumeOta:(BOOL)needResumeOta
                         otaModels:(NSArray<HwOtaDataModel *> *)dataModels
                    connectTimeout:(NSTimeInterval)connectTimeout
                     readyCallback:(HwBoolCallback)readyCallback
                  progressCallback:(HwBCFloatCallback)progressCallback
                    finishCallback:(HwBoolCallback)finishCallback;



/*!
 连接OTA外设名称直接OTA
 
 @param peripheralName OTA名称
 @param dataModels ota数据
 @param readyCallback 准备好之后回调
 @param progressCallback ota进度回调
 @param finishCallback 完成之后回调
 */
- (void) startOtaWithPeripheralName:(NSString *)peripheralName
                      needResumeOta:(BOOL)needResumeOta
                          otaModels:(NSArray<HwOtaDataModel *> *)dataModels
                      readyCallback:(HwBoolCallback)readyCallback
                   progressCallback:(HwBCFloatCallback)progressCallback
                     finishCallback:(HwBoolCallback)finishCallback;

/*!
 连接OTA外设名称直接OTA
 
 @param peripheralName OTA名称
 @param dataModels ota数据
 @param readyCallback 准备好之后回调
 @param progressCallback ota进度回调
 @param finishCallback 完成之后回调
 */
- (void) startOtaWithPeripheralName:(NSString *)peripheralName
                      needResumeOta:(BOOL)needResumeOta
                          otaModels:(NSArray<HwOtaDataModel *> *)dataModels
                     connectTimeout:(NSTimeInterval)connectTimeout
                      readyCallback:(HwBoolCallback)readyCallback
                   progressCallback:(HwBCFloatCallback)progressCallback
                     finishCallback:(HwBoolCallback)finishCallback;


/*!
 停止当前OTA
 
 @param callback 停止当前OTA操作
 */
- (void) stopOtaWithCallback:(HwBoolCallback)callback;


@end
