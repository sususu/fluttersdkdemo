#import "HwBluetoothCenter.h"
#import "HwJLOtaV2Manager.h"

@interface HwBluetoothCenter (JLOtaV2)

- (void)jlOtaV2SetLogLevel:(HwJLOtaLogLevel)logLevel;
- (HwJLOtaLogLevel)jlOtaV2LogLevel;

- (void)jlOtaV2StartWithBinData:(NSData *)binData
                  readyCallback:(HwBoolCallback)readyCallback
               progressCallback:(HwBCFloatCallback)progressCallback
                 finishCallback:(HwBoolCallback)finishCallback;

- (void)jlOtaV2Stop;

@end
