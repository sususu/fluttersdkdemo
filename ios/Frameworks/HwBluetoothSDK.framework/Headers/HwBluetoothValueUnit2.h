//
//  HwBluetoothValueUnit2.h
//  HwBluetoothSDK
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwBluetoothValueUnit2 : NSObject

@property(nonatomic, assign) NSUInteger type;
@property(nonatomic, assign) NSUInteger length;
@property(nonatomic, strong) NSData *value;

- (instancetype)initWithType:(NSUInteger)type length:(NSUInteger)length value:(NSData *)value;
- (instancetype)initWithType:(NSUInteger)type length:(NSUInteger)length intValue:(int)intValue;

+ (NSArray<HwBluetoothValueUnit2 *> *)unitsWithData:(NSData *)data;
+ (NSData *)dataFromUnits:(NSArray<HwBluetoothValueUnit2 *> *)units;

@end

NS_ASSUME_NONNULL_END
