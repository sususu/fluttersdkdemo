//
//  HwBluetoothDeviceRequestManager+DrinkWaterRecords.h
//  HwBluetoothSDK
//

#import "HwBluetoothDeviceRequestManager.h"
#import "HwDrinkWaterRecord.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^HwDrinkWaterRecordsChangedCallback)(NSArray<HwDrinkWaterRecord *> *records);

@interface HwBluetoothDeviceRequestManager (DrinkWaterRecords)

- (void)addDrinkWaterRecordsChangedCallback:(HwDrinkWaterRecordsChangedCallback)callback;
- (void)removeDrinkWaterRecordsChangedCallback:(HwDrinkWaterRecordsChangedCallback)callback;
- (void)removeAllDrinkWaterRecordsChangedCallbacks;
- (void)notifyDrinkWaterRecordsChanged:(NSArray<HwDrinkWaterRecord *> *)records;

@end

NS_ASSUME_NONNULL_END
