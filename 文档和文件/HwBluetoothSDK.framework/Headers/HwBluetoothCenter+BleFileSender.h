#import "HwBluetoothCenter.h"

typedef void(^BleFSLogBlock)(NSString *logMessage);

@interface HwBluetoothCenter (BleFileSender)

- (void)enterBleFileSenderReadyStatus:(uint16_t)protocol readyCallback:(HwBoolCallback)readyCallback;
- (void)exitBleFileSenderReadyStatus;

- (void)startBleFileSenderWithData:(NSData *)data
                           fileName:(NSString *)fileName
                        imageIndex:(int)imageIndex;

- (void)setBleFSLogBlock:(BleFSLogBlock)logBlock;

@end

