//
//  HwFileUtils.h
//  HwBluetoothSDK
//
//  Created by huawo01 on 2024/3/12.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, HwFileUtilsType) {
    HwFileUtilsTypeMP3 = 0,
    HwFileUtilsTypeWAV,
    HwFileUtilsTypeUnknown,
};


NS_ASSUME_NONNULL_BEGIN

@interface HwFileUtils : NSObject

/**
 检查文件类型的方法
 */
+ (HwFileUtilsType)checkFileType:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
