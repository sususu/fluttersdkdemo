//
//  HwDeviceInfo.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2024/6/17.
//

#import <Foundation/Foundation.h>
#import "HwDeviceDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface HwDeviceInfo : NSObject

@property(nonatomic, strong) NSString *Id;
@property(nonatomic, strong) NSString *type;
@property(nonatomic, strong) NSString *firmwareVersion;
@property(nonatomic, strong) NSData *features;
@property(nonatomic, strong) NSString *mac;
@property(nonatomic, assign) HwLanguage language;
@property(nonatomic, strong) NSArray *supportedLanguages;
@property(nonatomic, assign) NSInteger battery;
@property(nonatomic, strong) NSString *displayingWatchfaceId;
@property(nonatomic, assign) NSInteger watchfaceVersion;
@property(nonatomic, assign) NSInteger protocolVersion;
@property(nonatomic, assign) HwBindState bindState;
@property(nonatomic, strong) NSString *mapUUID;
@property(nonatomic, assign) BOOL mapAuthorized;

@end

NS_ASSUME_NONNULL_END
