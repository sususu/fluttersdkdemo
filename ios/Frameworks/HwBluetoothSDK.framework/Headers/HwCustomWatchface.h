//
//  HwCustomWatchface.h
//  Pods
//
//  Created by HuaWo on 2022/6/14.
//

#import <UIKit/UIKit.h>
#import "HwWidget.h"

NS_ASSUME_NONNULL_BEGIN

@interface HwCustomWatchface : NSObject

@property(nonatomic, assign) NSInteger Id;
@property(nonatomic, strong) UIImage *backgroundImage;
@property(nonatomic, assign) CGSize size;
@property(nonatomic, strong) UIImage *thumbnailImage;
@property(nonatomic, assign) CGSize thumbnailSize;
@property(nonatomic, assign) NSInteger widgetLayoutStyle;
@property(nonatomic, strong) NSArray<HwWidget *> *widgets;

@end

NS_ASSUME_NONNULL_END
