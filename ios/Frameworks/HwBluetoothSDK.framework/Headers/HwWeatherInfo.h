//
//  HwWeatherInfo.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2021/6/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwWeatherInfo : NSObject

@property(nonatomic, assign) NSInteger currentTemperature;              // current temperature
@property(nonatomic, assign) NSInteger minimumTemperature;              // min temperature
@property(nonatomic, assign) NSInteger maximumTemperature;              // max temperature

// 新增
@property(nonatomic, assign) NSInteger humidity;    // 湿度  (humidity)
@property(nonatomic, assign) NSInteger pressure;    // 大气压  (Atmospheric pressure)
@property(nonatomic, assign) NSInteger windDirection;   // 风向(0 - 36000)，最后两位在设备那边是小数点  (wind direction)
@property(nonatomic, assign) NSInteger windSpeed;       // 风速 (wind speed)
@property (nonatomic, copy) NSString *city;             //城市

// 体感温度、紫外线指数、日出时间、日落时间、降雨概率、降水量、能见度、空气质量指数

@property(nonatomic, assign) NSInteger sendibleTemperature; // 体感温度             (somatosensory temperature)
@property(nonatomic, assign) NSInteger ultravioletIndex;    // 紫外线指数                (UV index)
@property(nonatomic, assign) NSInteger sunriseHour;         // 日出小时                 Sunrise time (hour part)
@property(nonatomic, assign) NSInteger sunriseMinute;      // 日出分钟，跟日出小时组成日出时间     Sunrise time (min part)
@property(nonatomic, assign) NSInteger sunsetHour;          // 日落小时                             Sunset time (hour part)
@property(nonatomic, assign) NSInteger sunsetMinute;        // 日落分钟                             Sunset time (min part)

@property(nonatomic, assign) NSInteger rainfallProbability; // 降雨概率（%）                          Rainfall probability （%）
@property(nonatomic, assign) NSInteger precipitation;       // 降水量（单位 0.1mm）                    Precipitation （mm）
@property(nonatomic, assign) NSInteger visibility;          // 能见度（米）                           visibility （m）

/**
 美国标准：
 0-50 Good
 51-100Moderate
 101-150 Unhealthy for sensitive groups
 151-200 Unhealthy
 200-300 Very unhealthy
 301-500 Hazardous
 */
@property(nonatomic, assign) NSInteger airQuality;          // 空气质量指数                   Air quality index

/**
 今天
 每小时的天气（对应24个小时，24个值（整型），数组长度不是24，将被忽略）
 
 today

 Hourly weather (corresponding to 24 hours, 24 values (integer), array length is not 24, will be ignored)
 */

@property(nonatomic, strong) NSArray * _Nullable hoursTemperatures;

/**
 今天
 每小时的天气类型（对应24个小时，24个值（整型），数组长度不是24，将被忽略）
 
 
 today

 Weather type of each hour (corresponding to 24 hours, 24 values (integer), array length is not 24, will be ignored)
 */
@property(nonatomic, strong) NSArray * _Nullable hoursTypes;

/**
 第二天
 每小时的天气（对应24个小时，24个值（整型），数组长度不是24，将被忽略）
 
 
 the second day

 Hourly weather  (corresponding to 24 hours, 24 values (integer), array length is not 24, will be ignored)
 */

@property(nonatomic, strong) NSArray * _Nullable nHoursTemperatures;
/**
  第二天
 每小时的天气类型（对应24个小时，24个值（整型），数组长度不是24，将被忽略）
 
 the second day

 Weather type of each hour (corresponding to 24 hours, 24 values (integer), array length is not 24, will be ignored)
 */
@property(nonatomic, strong) NSArray * _Nullable nHoursTypes;

/**
 第三天
 每小时的天气（对应24个小时，24个值（整型），数组长度不是24，将被忽略）
 
 The third day

 Hourly weather  (corresponding to 24 hours, 24 values (integer), array length is not 24, will be ignored)
 */
@property(nonatomic, strong) NSArray * _Nullable nnHoursTemperatures;
/**
 第三天
 每小时的天气类型（对应24个小时，24个值（整型），数组长度不是24，将被忽略）
 
 
  The third day
  Weather type of each hour (corresponding to 24 hours, 24 values (integer), array length is not 24, will be ignored)
 */
@property(nonatomic, strong) NSArray * _Nullable nnHoursTypes;

/**
 第四天
 每小时的天气（对应24个小时，24个值（整型），数组长度不是24，将被忽略）
 
 The forth day
  Hourly weather  (corresponding to 24 hours, 24 values (integer), array length is not 24, will be ignored)
 */
@property(nonatomic, strong) NSArray * _Nullable nnnHoursTemperatures;
/**
 第四天
 每小时的天气类型（对应24个小时，24个值（整型），数组长度不是24，将被忽略）
 
 The forth day
   Weather type of each hour (corresponding to 24 hours, 24 values (integer), array length is not 24, will be ignored)
 */
@property(nonatomic, strong) NSArray * _Nullable nnnHoursTypes;

/**
 第五天
 每小时的天气类型（对应24个小时，24个值（整型），数组长度不是24，将被忽略）
 
 The Fifth Day
 Hourly weather  (corresponding to 24 hours, 24 values (integer), array length is not 24, will be ignored)
 */
@property(nonatomic, strong) NSArray * _Nullable nnnnHoursTemperatures;
/**
 第五天
 每小时的天气类型（对应24个小时，24个值（整型），数组长度不是24，将被忽略）
 
  The Fifth Day
 Weather type of each hour (corresponding to 24 hours, 24 values (integer), array length is not 24, will be ignored)
 */
@property(nonatomic, strong) NSArray * _Nullable nnnnHoursTypes;

/**
 
 天气类型  如 ‘下雨’、‘多云’
 
 weather type, for example 'rainy' 'sunny', it's value depends on your watch
 */
@property(nonatomic, assign) NSInteger weatherType;

@property(nonatomic, assign) NSInteger windPowerLevel;

@end

NS_ASSUME_NONNULL_END
