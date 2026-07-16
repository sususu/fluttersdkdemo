//
//  HwBluetoothCenter+DrinkWater.h
//  HwBluetoothSDK
//

#import "HwBluetoothCenter.h"
#import "HwDrinkWaterRecord.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^HwDrinkWaterRecordsCallback)(NSArray<HwDrinkWaterRecord *> * _Nullable records, NSError * _Nullable error);
typedef void (^HwDrinkWaterRecordIdsCallback)(NSArray<NSNumber *> * _Nullable ids, NSError * _Nullable error);

@interface HwBluetoothCenter (DrinkWater)

- (HwBluetoothTask *)getAvailableDrinkWaterRecordIdsWithCallback:(HwDrinkWaterRecordIdsCallback)callback;
- (HwBluetoothTask *)getAllDrinkWaterRecordsWithCallback:(HwDrinkWaterRecordsCallback)callback;
- (HwBluetoothTask *)addDrinkWaterRecord:(HwDrinkWaterRecord *)record callback:(HwBoolCallback)callback;
- (HwBluetoothTask *)editDrinkWaterRecord:(HwDrinkWaterRecord *)record callback:(HwBoolCallback)callback;
- (HwBluetoothTask *)deleteDrinkWaterRecordWithId:(NSInteger)recordId callback:(HwBoolCallback)callback;
- (HwBluetoothTask *)deleteAllDrinkWaterRecordsWithCallback:(HwBoolCallback)callback;
- (HwBluetoothTask *)setAllDrinkWaterRecords:(NSArray<HwDrinkWaterRecord *> *)records callback:(HwBoolCallback)callback;

@end

NS_ASSUME_NONNULL_END
