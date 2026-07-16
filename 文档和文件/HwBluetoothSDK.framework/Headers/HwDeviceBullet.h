//
//  HwDeviceBullet.h
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HwBulletAnimationType) {
    HwBulletAnimationTypeToEnd = 0x00,
    HwBulletAnimationTypeLeftCircleAroundToEnd,
    HwBulletAnimationTypeRightCircleAroundToEnd
};

@class HwDeviceBulletBoxStyle;
@class HwBluetoothValueUnit;
@interface HwDeviceBullet : NSObject

@property(nonatomic, assign) bool loop;
@property(nonatomic, assign) HwBulletAnimationType animationType;
@property(nonatomic, assign) NSInteger font;
@property(nonatomic, assign) NSInteger fontSize;
@property(nonatomic, strong) UIColor *textColor;
@property(nonatomic, strong) HwDeviceBulletBoxStyle *boxStyle;
@property(nonatomic, assign) NSInteger survivalTime;
@property(nonatomic, assign) NSInteger animationDuration;
@property(nonatomic, assign) NSInteger animationDelay;
@property(nonatomic, assign) CGFloat startX;
@property(nonatomic, assign) CGFloat startY;
@property(nonatomic, assign) CGFloat endX;
@property(nonatomic, assign) CGFloat endY;
@property(nonatomic, assign) CGFloat watchWidth;
@property(nonatomic, assign) CGFloat watchHeight;
@property(nonatomic, copy) NSString *text;

- (HwBluetoothValueUnit *) toValueUnit;

@end

@interface HwDeviceBulletBoxStyle : NSObject

@property(nonatomic, strong) UIColor *backgroundColor;
@property(nonatomic, strong) UIColor *borderColor;
@property(nonatomic, assign) int borderWidth;

@end

NS_ASSUME_NONNULL_END
