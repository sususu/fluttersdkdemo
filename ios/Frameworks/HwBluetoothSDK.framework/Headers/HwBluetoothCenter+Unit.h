//
//  HwBluetoothCenter+Unit.h
//  CocoaLumberjack
//
//  Created by sujiang on 2020/8/27.
//

#import "HwBluetoothCenter.h"

/*!
新增0x27  应用单位设置类型[app unit set Type]
 
 - HwAppUnitDistanceType:距离[distance](0x00：公制 // 0x01：英制)
 - HwAppUnitTemperatureType:体温[temperature](0x00：摄氏 // 0x01：华氏)
 - HwAppUnitHour12Or24Type:时间[time](0x00：十二小时制 //0x01：二十四小时制)
 - HwUnitWaterType:喝水量[water](0x00：毫升 //0x01：盎司)

 - HwAppUnitAllType :查询所有[all]
 */
typedef NS_ENUM(NSInteger, HwUnitType)
{
    HwUnitDistanceType = 0x01,
    HwUnitTemperatureType = 0x02,
    HwUnitHour12Or24Type = 0x03,
    HwUnitWaterType = 0x04,

    HwUnitAllType = 0xff
};

/*!
 value unit【数值单位】
 - HwUnitMetric: 公制
 - HwUnitBritish: 英制
 */
typedef NS_ENUM(NSInteger, HwUnit) {
    HwUnitMetric = 0,
    HwUnitBritish = 1
};

typedef NS_ENUM(NSInteger, HwWaterUnit) {
    HwWaterUnitML = 0,
    HwWaterUnitOZ = 1
};


@interface HwUnitInfoModel : NSObject

@property (unsafe_unretained, nonatomic) HwUnitType unitType;
@property (unsafe_unretained, nonatomic) NSInteger value;

@end

typedef void (^HwUnitCallback)(HwUnit unit, NSError *_Nullable error);

typedef void (^HwWaterUnitCallback)(HwUnit unit, NSError *_Nullable error);

typedef void (^HwUnitInfoCallback)(HwUnitInfoModel *_Nullable model, NSError *_Nullable error);

typedef void (^HwUnitInfosCallback)(NSArray<HwUnitInfoModel *> *_Nullable unitModels, NSError *_Nullable error);

@interface HwBluetoothCenter (Unit)

/*! @brief
 设置距离的单位 [set units of distance]
 0 ----> 公里 [kilometers]
 1 ----> 英里 [miles]
 
 @param unit 单位
 @param callback 回调
 */
- (HwBluetoothTask *_Nullable) setUnit:(HwUnit)unit
                              callback:(HwBoolCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) getUnitWithCallback:(HwUnitCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) setWaterUnit:(HwWaterUnit)wu
                                   callback:(HwBoolCallback _Nullable)callback;
- (HwBluetoothTask *_Nullable) getWaterUnitWithCallback:(HwWaterUnitCallback _Nullable)callback;


- (HwBluetoothTask *_Nullable) getUnitByType:(HwUnitType)unitType
                                    callback:(HwUnitInfoCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) getAllUnitsWithCallback:(HwUnitInfosCallback _Nullable)callback;

- (HwBluetoothTask *_Nullable) setUnitForType:(HwUnitType)unitType
                               value:(NSInteger)value
                            callback:(HwBoolCallback _Nullable)callback;


- (HwBluetoothTask *_Nullable)setUnitWithUnitModels:(NSArray <HwUnitInfoModel *> *_Nullable)unitModels
callback:(HwBoolCallback _Nullable)callback;


//- (HwBluetoothTask *) quickQueryGPSTrackLocationsWithTrackIndex:(NSInteger)trackIndex locationsNum:(NSInteger)locationsNum callback:(HwBCArrayCallback)callback;

@end

