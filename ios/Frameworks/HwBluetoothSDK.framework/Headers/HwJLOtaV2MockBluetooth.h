#import <Foundation/Foundation.h>
#import "HwJLOtaV2Manager.h"

NS_ASSUME_NONNULL_BEGIN

@interface HwJLOtaV2MockBluetooth : NSObject <HwJLOtaV2Transport>

@property (nonatomic, assign, nullable) HwJLOtaV2Manager *manager;
@property (nonatomic, assign) BOOL bitmapHasDifference;

- (instancetype)initWithManager:(nullable HwJLOtaV2Manager *)manager;
- (void)pushResponseData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
