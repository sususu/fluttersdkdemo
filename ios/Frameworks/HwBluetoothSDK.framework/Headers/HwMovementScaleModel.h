//
//  HwMovementScaleModel.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2021/6/24.
//

#import <Foundation/Foundation.h>
#import "HwDeviceDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface HwMovementScaleModel : NSObject

@property(nonatomic, assign) HwScaleContentType type;
@property(nonatomic, assign) HwSocialType socialType;
@property(nonatomic, copy) NSString *content;

@end

NS_ASSUME_NONNULL_END
