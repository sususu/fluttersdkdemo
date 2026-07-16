//
//  HwWidget.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2021/6/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HwWidgetType)
{
    HwWidgetTypeHeartRate = 0x00,
    HwWidgetTypeStep = 0x01,
    HwWidgetTypeCalorie = 0x02,
    HwWidgetTypeDistance = 0x03,
    HwWidgetTypeDate = 0x04,
    HwWidgetTypeDial = 0x05,
    HwWidgetTypeWeather = 0x06,
    HwWidgetTypeTimeHands = 0x07,
    HwWidgetTypeBattery = 0x08,
    HwWidgetTypeDuration = 0x09,
    HwWidgetTypeHomezone = 0x0A,
    HwWidgetTypeBackgroundColor = 0x0B,
    HwWidgetTypeActivityGraph = 0x0C,
    HwWidgetTypeTime = 0x0D,                  //时间（22:15）
    HwWidgetTypeReminder = 0x0E,              //消息提醒
    HwWidgetTypeTimeZone = 0x0F,               //时区
    HwWidgetTypePointerHour = 0x10,             // 时针
    HwWidgetTypePointerMinute = 0x11,             // 分针
    HwWidgetTypePointerSecond = 0x12               // 秒针
    // ...
};

@protocol HwFreeWidgetProtocol <NSObject>

@required
- (HwWidgetType)type;
- (int)widgetX;
- (int)widgetY;
- (int)widgetWidth;
- (int)widgetHeight;

- (int)colorR;
- (int)colorG;
- (int)colorB;
- (int)colorA;

- (int)widgetStyle;
// if YES, colorR,G,B,A must be set
- (BOOL) needColour;
// if YES, width, height must be set
- (BOOL) needResize;
// if YES, x, y must be set
- (BOOL) needLocate;
// select different icon for widget
// it's value depend on watch's widget icons count, maybe 1,2,3,4,5...
- (BOOL) needStyle;

- (BOOL) needTimezone;

// timezone
- (NSString *)iata;
- (NSString *)timezone;

@end

@interface HwWidget : NSObject<HwFreeWidgetProtocol>

@property(nonatomic, assign) HwWidgetType type;
@property(nonatomic, assign) NSInteger byteLength;

/**
 widget position x
 */
@property(nonatomic, assign) NSInteger x;

/**
 widget position y
 */
@property(nonatomic, assign) NSInteger y;

/**
 this property may be color style, may be others, depends on different devices
 */
@property(nonatomic, assign) NSInteger style;

// rgba background, these four properties only work for
// HwWidgetTypeBackgroundColor which presents pure color watchface
@property(nonatomic, assign) NSInteger r;
@property(nonatomic, assign) NSInteger g;
@property(nonatomic, assign) NSInteger b;
@property(nonatomic, assign) NSInteger a;

@end

NS_ASSUME_NONNULL_END
