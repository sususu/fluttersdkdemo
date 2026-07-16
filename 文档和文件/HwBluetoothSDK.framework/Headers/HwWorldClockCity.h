//
//  HwWorldClockCity.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2022/6/16.
//

#import <Foundation/Foundation.h>
#import "HwDeviceDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface HwWorldClockCity : NSObject

@property(nonatomic, assign) NSInteger Id;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, strong) NSTimeZone *timezone;

- (HwWorldClockCity *) initWithId:(NSInteger)Id
                             name:(NSString *)name
                         timezone:(NSTimeZone *)timezone;

- (HwTimezoneArea) area;
- (NSInteger) hour;
- (NSInteger) minute;

@end

NS_ASSUME_NONNULL_END
