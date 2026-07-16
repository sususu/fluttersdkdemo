//
//  HwBluetoothValueUnit.h
//  HwBluetoothSDK
//
//  Created by SuJiang on 2019/6/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwBluetoothValueUnit : NSObject

@property(nonatomic, assign) NSUInteger length;
@property(nonatomic, assign) NSUInteger type;
@property(nonatomic, strong) NSData *value;

- (id) initWithType:(NSUInteger)type
             length:(NSUInteger)length
              value:(NSData *)value;

- (id) initWithType:(NSUInteger)type
             length:(NSUInteger)length
           intValue:(int)intValue;

- (id) initWithType:(NSUInteger)type
        stringValue:(NSString *)stringValue;


+ (NSArray<HwBluetoothValueUnit *> *) unitsWithData:(NSData *)data;
+ (NSData *) dataFromUnits:(NSArray<HwBluetoothValueUnit *> *)units;
+ (NSArray<HwBluetoothValueUnit *> *) unitsWithData2:(NSData *)data;
+ (NSData *) dataFromUnitsLength2:(NSArray<HwBluetoothValueUnit *> *)units;

@end

NS_ASSUME_NONNULL_END
