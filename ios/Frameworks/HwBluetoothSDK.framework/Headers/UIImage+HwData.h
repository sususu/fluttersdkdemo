//
//  UIImage+HwData.h
//  HwBluetoothSDK_Example
//
//  Created by sujiang on 2020/6/22.
//  Copyright © 2020 SuJiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef NS_ENUM(NSInteger, HwImageDataFormat)
{
    HwImageDataFormatRGB565,
    HwImageDataFormatRGB888,
    HwImageDataFormatRGB565Dither,
    HwImageDataFormatRGB565GrayDither,
    HwImageDataFormatRGB565NoHeadDither
};

@interface UIImage (HwData)
- (NSData *) dataWithFormat:(HwImageDataFormat)format;

@end



