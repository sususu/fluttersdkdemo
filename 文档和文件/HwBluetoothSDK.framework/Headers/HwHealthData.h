//
//  HwHealthData.h
//  Pods
//
//  Created by HuaWo on 2025/3/28.
//

#import <Foundation/Foundation.h>
#import "NSDate+HwSDK.h"

NS_ASSUME_NONNULL_BEGIN

@class HwBloodPressure;
@class HwHealthDailyData;
@interface HwHealthData : NSObject

@property(nonatomic, assign) NSInteger gender;
@property(nonatomic, assign) NSInteger age;
@property(nonatomic, assign) NSInteger weight;
@property(nonatomic, assign) NSInteger height;
@property(nonatomic, assign) NSInteger unit;

@property(nonatomic, strong) NSArray<HwHealthDailyData *> *dailyDataList;

- (HwHealthData *) initWithData:(NSData *)data;

@end

@interface HwHealthDailyData : NSObject
@property(nonatomic, assign) NSInteger day;
@property(nonatomic, assign) NSInteger step;
@property(nonatomic, assign) NSInteger minHr;
@property(nonatomic, assign) NSInteger maxHr;
@property(nonatomic, assign) NSInteger avgHr;

@property(nonatomic, assign) NSInteger minSpO2;
@property(nonatomic, assign) NSInteger maxSpO2;
@property(nonatomic, assign) NSInteger avgSpO2;

@property(nonatomic, assign) NSInteger minStress;
@property(nonatomic, assign) NSInteger maxStress;
@property(nonatomic, assign) NSInteger avgStress;

@property(nonatomic, strong) HwBloodPressure *minBP;
@property(nonatomic, strong) HwBloodPressure *maxBP;
@property(nonatomic, strong) HwBloodPressure *avgBP;

@property(nonatomic, assign) NSInteger sleep;
@property(nonatomic, assign) NSInteger PAI;

- (HwHealthDailyData *) initWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
