#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HwJLOtaV2Transport <NSObject>
- (void)otaWriteData:(NSData *)data;
@end

typedef NS_ENUM(NSUInteger, HwJLOtaMode) {
    HwJLOtaModeFull = 1,         // 全量升级
    HwJLOtaModeIncremental = 2,  // 增量升级
    HwJLOtaModeDiff = 3          // 差分升级
};

typedef NS_ENUM(NSUInteger, HwJLOtaFileType) {
    HwJLOtaFileTypeFirmware = 1,             // OTA_BIN_UFW_TYPE：固件文件
    HwJLOtaFileTypeResource = 2,             // OTA_BIN_MODE_TYPE：内部资源文件
    HwJLOtaFileTypeWatch = 3,                // OTA_BIN_WATCH_TYPE：表盘文件
    HwJLOtaFileTypeIncrementalResource = 4,  // OTA_BIN_ADD_RES_TYPE：增量资源文件
    HwJLOtaFileTypeFatPartition = 5,         // OTA_BIN_FAT_NOR_TYPE：FAT 分区
    HwJLOtaFileTypeExternalResource = 6,     // OTA_BIN_EXT_RES_TYPE：外部资源文件
    HwJLOtaFileTypeReserved = 7              // OTA_BIN_RESV：保留
};

typedef NS_ENUM(NSUInteger, HwJLOtaLogLevel) {
    HwJLOtaLogLevelNone = 0,
    HwJLOtaLogLevelError = 1,
    HwJLOtaLogLevelInfo = 2,
    HwJLOtaLogLevelDebug = 3
};

typedef void (^HwJLOtaReadyCallback)(BOOL ready, NSError *_Nullable error);
typedef void (^HwJLOtaProgressCallback)(double progress);
typedef void (^HwJLOtaFinishCallback)(BOOL success, NSError *_Nullable error);
typedef void (^HwJLOtaLogCallback)(NSString *log);

@interface HwJLOtaSegment : NSObject
@property (nonatomic, assign) uint32_t fileType;
@property (nonatomic, assign) uint32_t startAddIndex;
@property (nonatomic, assign) uint32_t fileLen;
@end

@interface HwJLOtaV2Manager : NSObject

@property (nonatomic, assign, readonly) id<HwJLOtaV2Transport> transport;
@property (nonatomic, copy, nullable) HwJLOtaLogCallback logCallback;
@property (nonatomic, assign) NSTimeInterval ackTimeoutSeconds;
@property (nonatomic, assign) HwJLOtaLogLevel logLevel;

- (instancetype)initWithTransport:(id<HwJLOtaV2Transport>)transport;

- (void)startWithBinData:(NSData *)binData
           readyCallback:(nullable HwJLOtaReadyCallback)readyCallback
        progressCallback:(nullable HwJLOtaProgressCallback)progressCallback
          finishCallback:(nullable HwJLOtaFinishCallback)finishCallback;

- (void)handleIncomingData:(NSData *)data;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
