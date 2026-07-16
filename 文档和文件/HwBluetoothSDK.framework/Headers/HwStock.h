//
//  HwStock.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2021/6/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwStock : NSObject

@property(nonatomic, assign) UInt8 Id;
@property(nonatomic, strong) NSString *name;
// 0.001$ or 0.001¥
@property(nonatomic, assign) UInt32 closingPrice;
// 0.001$ or 0.001¥
@property(nonatomic, assign) UInt32 currentPrice;
@property(nonatomic, assign) int changepercent;

// second
@property(nonatomic, assign) UInt32 updateTime;

@end

NS_ASSUME_NONNULL_END
