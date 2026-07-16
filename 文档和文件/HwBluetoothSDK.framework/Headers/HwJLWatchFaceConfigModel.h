//
//  HwJLWatchFaceConfigModel.h
//  HwBluetoothSDK
//
//  Created by kingwear on 2026/2/11.
//

#import <Foundation/Foundation.h>

/**
 表盘图片显示模式枚举
 */
typedef NS_ENUM(NSInteger, HwJLWatchFaceConfigModelDisplayModeType) {
    HwJLWatchFaceDisplayModeType_SingleImage = 1,  // 单张图片
    HwJLWatchFaceDisplayModeType_QueueShow = 2,    // 队列显示
    HwJLWatchFaceDisplayModeType_RandomShow = 3    // 随机显示
};

/**
 表盘组件类型枚举（对应截图中的可配置组件）
 */
typedef NS_ENUM(NSInteger, HwJLWatchFaceConfigModelComponentType) {
    HwJLWatchFaceComponentType_Time = 1,      // 时间
    HwJLWatchFaceComponentType_Date = 2,     // 日期
    HwJLWatchFaceComponentType_HeartRate = 3,// 心率
    HwJLWatchFaceComponentType_Steps = 4,     // 步数
    HwJLWatchFaceComponentType_Distance = 5,  // 距离
    HwJLWatchFaceComponentType_Calories = 6,  // 卡路里
    HwJLWatchFaceComponentType_ActiveTime = 7,// 活动时长
    HwJLWatchFaceComponentType_Weather = 8,   // 天气
    HwJLWatchFaceComponentType_Sleep = 9,    // 睡眠
    HwJLWatchFaceComponentType_Battery = 10   // 电池
};

@interface HwJLWatchFaceConfigCompentModel : NSObject

@property (nonatomic, assign) HwJLWatchFaceConfigModelComponentType compentType;
@property (nonatomic, assign) CGPoint position;

@end

NS_ASSUME_NONNULL_BEGIN
@interface HwJLWatchFaceConfigModel : NSObject

@property(nonatomic, assign) HwJLWatchFaceConfigModelDisplayModeType displayModeType; // 表盘图片显示模式枚举
@property(nonatomic, assign) int coverImageIndex; // 0-x(图⽚的张数下标)
@property(nonatomic, assign) NSInteger imageCount; // 图片总数
@property(nonatomic, assign) int pointerStyle; // 指针⻛格
@property(nonatomic, strong) NSString *rgbColorStr; // ⽂字颜⾊
@property(nonatomic, strong) NSArray<HwJLWatchFaceConfigCompentModel *> *compentArr; // 组合元素

@end

NS_ASSUME_NONNULL_END
