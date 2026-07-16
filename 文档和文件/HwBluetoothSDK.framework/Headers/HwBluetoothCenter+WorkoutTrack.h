//
//  HwBluetoothCenter+WorkoutTrack.h
//  CocoaLumberjack
//
//  Created by sujiang on 2019/9/10.
//

#import "HwBluetoothCenter.h"

@class CLLocation;

typedef NS_ENUM(NSInteger, HwAGPSPeriodType) {
    HwAGPSPeriodDailyType = 0x04,
    HwAGPSPeriodWeeklyType = 0x02
};

@interface HwWKGPSLocation : NSObject
//轨迹序号
@property (nonatomic,assign) NSInteger hIndex;

////数据有效性及gps索引
@property (nonatomic,assign) NSInteger gpsIndex;

@property (nonatomic,assign) NSInteger time;

//北纬为0 南纬为1
@property (nonatomic,assign) BOOL isSouthLatitude;
//纬度，单位/1000000
@property (nonatomic,assign) NSInteger latitute;

//东经为0 西经为1
@property (nonatomic,assign) BOOL isWestLongitude;

//经度，单位/1000000
@property (nonatomic,assign) NSInteger longitude;

@property (nonatomic,assign) NSInteger distance;

//时速，单位km/h
@property (nonatomic,assign) NSInteger speed;

@property (readonly, nonatomic, unsafe_unretained) BOOL isSeparatorPoint;

@end

@interface HwGPSTrack : NSObject

//轨迹序号
@property (nonatomic,assign) NSInteger trackIndex;
//轨迹对应的gps点个数
@property (nonatomic,assign) NSInteger gpsLocationNum;
//轨迹开始时间戳
@property (nonatomic,assign) NSInteger startTimeStamp;

@end

NS_ASSUME_NONNULL_BEGIN

@interface HwBluetoothCenter (WorkoutTrack)

/**
 查询所有轨迹GPS坐标总个数（index：0）或查询某条轨迹GPS坐标总个数（index：1 ~ 254）
 
 @param index index：0查询所有轨迹坐标总个数，index：1~254查询所传入序号对应轨迹的坐标个数
 @param callback callback
 @return HwBluetoothTask
 */
- (HwBluetoothTask *) queryGPSLocationsNumOfAllTracksOrATrackWithIndex:(NSInteger)index  callback:(HwBCIntegerCallback)callback;

/**
 查询设备上已有GPS坐标的轨迹及每条轨迹对应的gps坐标个数
 
 @param callback 返回HwGPSTrack元素的数组
 @return HwBluetoothTask
 */
- (HwBluetoothTask *) queryGPSTracksOnDeviceAndTheGPSLocationNumToATrackCallBack:(HwBCArrayCallback)callback;

/**
 根据轨迹序号获取gps轨迹点（轨迹点长度为22字节）（trackIndex）
 
 @param trackIndex trackIndex:0获取所有坐标点，trackIndex:1~254获取指定trackIndex轨迹的坐标点
 @param locationsNum gps坐标个数
 @param callback callback
 @return HwBluetoothTask
 */
- (HwBluetoothTask *) queryGPSTrackLocationsWithTrackIndex:(NSInteger)trackIndex locationsNum:(NSInteger)locationsNum callback:(HwBCArrayCallback)callback;

/**
 快速查询指定GPS轨迹坐标(轨迹点长度为14字节则进行快速解析，如果获取的轨迹点为22字节则和上面解析方法一样)
 
 @param trackIndex 轨迹序号trackIndex:0获取所有坐标点，trackIndex:1~254获取指定trackIndex轨迹的坐标点
 @param locationsNum gps坐标个数
 @param callback callback
 @return HwBluetoothTask
 */
- (HwBluetoothTask *) quickQueryGPSTrackLocationsWithTrackIndex:(NSInteger)trackIndex locationsNum:(NSInteger)locationsNum callback:(HwBCArrayCallback)callback;

/**
 删除手表上指定序号（index）的GPS数据
 
 @param trackIndex 轨迹序号（1 ~ 254）
 @param callback 返回bool
 @return HwBluetoothTask
 */
- (HwBluetoothTask *) deleteGPSDataOnDeviceWithTrackIndex:(NSInteger)trackIndex callback:(HwBoolCallback)callback;

/**
 删除手表上所有的GPS数据
 
 @param callback 返回bool
 @return HwBluetoothTask
 */
- (HwBluetoothTask *) deleteAllGPSDataOnDeviceWithCallback:(HwBoolCallback)callback;

/// 向设备请求AGPS最后的更新时间戳
/// @param type 星历数据的过期类型
/// @param callback 返回时间戳
- (HwBluetoothTask *)queryAGPSUpdateTimeStampFromDeviceWithPeriodType:(HwAGPSPeriodType)type callback:(HwBCIntegerCallback)callback;

/// 向设备发送OTAAGPS的最新的时间戳
/// @param timeStamp 时间戳
/// @param type 星历数据的过期类型
/// @param callback 是否成功
- (HwBluetoothTask *)commitAGPSUpdateTimeToDeviceWithPeriodType:(HwAGPSPeriodType)type typeTimeStamp:(NSInteger)timeStamp callback:(HwBoolCallback)callback;

/// 发送手机当前位置给设备
/// @param location 当前位置
/// @param callback 回调
- (HwBluetoothTask *)sendCurrentLocationToDeviceWithLocation:(CLLocation * _Nonnull)location callback:(HwBoolCallback)callback;


/// 在后台t无感上传AGPS数据给设备
/// @param agpsData AGPS数据
/// @param callback 回调
- (void)sendAGPSDataInBackground:(NSData *)agpsData callback:(HwBoolCallback)callback;


/// 在后台无感上传AGPS数据给设备
/// @param agpsData AGPS数据
/// @param callback 回调
- (void)sendAGPSDataInBackgroundWithApgsData:(NSData *)agpsData callback:(HwBoolCallback)callback;

@end

NS_ASSUME_NONNULL_END
