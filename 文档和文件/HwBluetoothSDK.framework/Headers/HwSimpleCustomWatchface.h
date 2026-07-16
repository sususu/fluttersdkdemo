//
//  HwSimpleCustomWatchface.h
//  Pods
//
//  Created by HuaWo on 2022/7/12.
//

#import "HwCustomWatchface.h"

NS_ASSUME_NONNULL_BEGIN

@interface HwSimpleCustomWatchface : HwCustomWatchface

@property(nonatomic, strong) UIColor *timeColor;
@property(nonatomic, strong) UIColor *dateColor;

- (id) initWithBackgroundImage:(UIImage *)backgroundImage
           backgroundImageSize:(CGSize)backgroundImageSize
                thumbnailImage:(UIImage *)thumbnailImage
            thumbnailImageSize:(CGSize)thumbnailImageSize
                     timeColor:(UIColor *)timeColor
                     dateColor:(UIColor *)dateColor;

@end

NS_ASSUME_NONNULL_END
