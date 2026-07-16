//
//  HwSocialApp.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2022/1/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwSocialApp : NSObject

@property(nonatomic, strong) NSString *bundleId;
@property(nonatomic, assign) int type;
@property(nonatomic, strong) NSData *iconBin;
@property(nonatomic, assign) int iconWidth;

+ (NSData *) listToOtaBin:(NSArray<HwSocialApp *> *)list;

- (HwSocialApp *) initWithType:(int)type;

@end

NS_ASSUME_NONNULL_END
