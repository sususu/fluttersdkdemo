//
//  HwBluetoothTimer.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2022/8/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwBluetoothTimer : NSObject

@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic, assign) NSTimeInterval timeout;

- (id) initWithTimeout:(NSTimeInterval)timeout;

- (void) startTimer;

- (void) timeIsUp;
- (void) removeTimer;

@end

NS_ASSUME_NONNULL_END
