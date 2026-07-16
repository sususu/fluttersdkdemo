//
//  HwBluetoothCenter+WatchFace.h
//  CocoaLumberjack
//
//  Created by sujiang on 2020/6/17.
//

#import "HwBluetoothCenter.h"
#import "HwWidget.h"

@interface HwDeviceWatchFacesInfo : NSObject

@property (readonly, unsafe_unretained, nonatomic) NSInteger watchFacesCount;
@property (readonly, strong, nonatomic) NSArray <NSNumber *>* watchFaceIds;

@end

@class HwWatchFacePackage;
typedef void (^HwSetCustomWatchFaceReadyCallback)(BOOL b, NSError *error);
typedef void (^HwSetCustomWatchFaceFinishCallback)( BOOL b, NSError *error);
typedef void (^HwSetCustomWatchFaceProgressCallback)(float f, NSError *error);
typedef void (^HwNewCustomWatchFaceOtaAddressCallback)(NSData *otaAddress, BOOL needOTA, NSError *error);

@interface HwBluetoothCenter (WatchFace)


// new custom watchface APIs

/**
 get all watchface IDs from device
 each ID is an Integer with 4bit
 
 @param callback ID array
 @return task
 */
- (HwBluetoothTask *) getWatchFaceIDsWithCallback:(HwBCArrayCallback)callback;


/**
 get watchface ota address
 
 @param ID which watchface
 @param callback callback ota address data
 @return task
 */
- (HwBluetoothTask *) getWatchFaceOtaAddressForID:(NSInteger)ID
                                         callback:(HwNewCustomWatchFaceOtaAddressCallback)callback;


/**
 delete all custom watchface
 only work for apollo3、 only work for apollo3、 only work for apollo3
 
 @param callback success or not callback
 @return task
 */
- (HwBluetoothTask *) deleteAllWatchFacesWithCallback:(HwBoolCallback)callback;

/**
 delete custom watchface by ID
 
 @param callback success or not callback
 @return task
 */
- (HwBluetoothTask *) deleteWatchFaceOfID:(NSInteger)ID
                                 callback:(HwBoolCallback)callback;

- (HwBluetoothTask *) setWidgets:(NSArray<HwWidget *> *)widgets
                    widgetLayout:(NSInteger)widgetLayout
                  forWatchFaceID:(NSInteger)ID
                        callback:(HwBoolCallback)callback;

- (HwBluetoothTask *) setFreeWidgets:(NSArray < id <HwFreeWidgetProtocol>> *)freeWidgets
                      forWatchFaceID:(NSInteger)ID
                            callback:(HwBoolCallback)callback;



/// 选择一个已经存在手表中的表盘
/// @param watchFaceId 表盘ID，一般用时间戳
/// @param callback 回调
- (HwBluetoothTask *)selectWatchFaceWithId:(NSInteger)watchFaceId callback:(HwBoolCallback)callback;


/// 删除一个已经存在手表中的表盘
/// @param watchFaceId 表盘ID，一般用时间戳
/// @param callback 回调
- (HwBluetoothTask *)deleteWatchFaceWithId:(NSInteger)watchFaceId callback:(HwBoolCallback)callback;


/// 获取手表已经安装的所有表盘的id
/// @param callback 回调
- (HwBluetoothTask *)getDeviceWatchFacesInfoWithCallback:(void(^)(HwDeviceWatchFacesInfo *info, NSError *error))callback;

- (HwBluetoothTask *_Nonnull) getSifliDisplayingWatchfaceNameWithCallback:(HwStringCallback _Nonnull)callback;
- (HwBluetoothTask *_Nonnull) getSifliInstalledWatchfaceNamesWithCallback:(HwBCStringArrayCallback _Nonnull)callback;
- (HwBluetoothTask *_Nonnull) setSifliDisplayingWatchfaceName:(NSString *_Nonnull)name
                                                     callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nonnull) delWatchfaceByWatchfaceName:(NSString *_Nonnull)name
                                                 callback:(HwBoolCallback _Nullable)callback;

@end

