//
//  HwCameraImage.h
//  HwBluetoothSDK
//
//  Created by kingwear on 2025/11/25.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, HwCameraImageSupportType)
{
    HwCameraImageSupportTypeJPG = 0x00,
    HwCameraImageSupportTypePNG = 0x01
};

typedef NS_ENUM(NSInteger, HwCameraImageColorType)
{
    HwCameraImageColorTypeRGB565 = 0x00,
    HwCameraImageColorTypeOther = 0x01,
};

@interface HwCameraImage : NSObject

@property(nonatomic, assign) HwCameraImageSupportType imageSupportType;
@property(nonatomic, assign) HwCameraImageColorType imageColorType;
@property(nonatomic, assign) NSInteger imageWidth;
@property(nonatomic, assign) NSInteger imageHeight;
@property(nonatomic, assign) NSInteger protocalVersion;

+ (HwCameraImage *)initWihtData:(NSData *)data;

@end
