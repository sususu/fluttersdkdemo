//
//  HwBluetoothCenter+GPS.h
//  Apps
//
//  Created by sujiang on 2018/9/14.
//  Copyright © 2021年 huawo. All rights reserved.
//

#import "HwBluetoothCenter.h"


@interface HwGPSLocation : NSObject
//轨迹序号
@property (nonatomic,assign) NSInteger hIndex;

//数据有效性及gps索引
@property (nonatomic,assign) NSInteger gpsIndex;
@property (nonatomic,assign) NSInteger sportTime;

//北纬为1 南纬为-1
@property (nonatomic,assign) NSInteger northSouthLat;
//纬度，单位/1000000
@property (nonatomic,assign) NSInteger latitute;

//东经为1 西经为-1
@property (nonatomic,assign) NSInteger westernEastLnt;
//经度，单位/1000000
@property (nonatomic,assign) NSInteger longitude;

@property (nonatomic,assign) NSInteger distance;
//时速，单位10m/h
@property (nonatomic,assign) NSInteger speed;

@property (readonly, nonatomic, unsafe_unretained) BOOL isSeparatorPoint;

@end

@interface HwBluetoothCenter (GPS)

//查询所有GPS轨迹坐标总个数
- (HwBluetoothTask *) queryAllGPSLocationsNumWithIndex:(NSInteger)index Callback:(HwBCIntegerCallback)callback;

//查询指定GPS轨迹坐标总个数
- (HwBluetoothTask *) queryGPSLocationsNumWithTrackID:(NSInteger)trackID Callback:(HwBCIntegerCallback)callback;


- (HwBluetoothTask *) deleteGPSLocationsWithTrackID:(NSInteger)trackID Callback:(HwBoolCallback)callback;

- (HwBluetoothTask *) deleteAllGPSLocationsWithCallback:(HwBoolCallback)callback;

//查询指定GPS轨迹坐标
- (HwBluetoothTask *) queryGPSLocationsWithTrackID:(NSInteger)trackID LocationsNum:(NSInteger)locationsNum Callback:(HwBCArrayCallback)callback;

//快速查询指定GPS轨迹坐标
- (HwBluetoothTask *) quickQueryGPSLocationsWithTrackID:(NSInteger)trackID LocationsNum:(NSInteger)locationsNum Callback:(HwBCArrayCallback)callback;


@end
