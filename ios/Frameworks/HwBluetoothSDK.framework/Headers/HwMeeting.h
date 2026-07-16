//
//  HwMeeting.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2025/3/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HwMeetingContentType) {
    HwMeetingContentTypeTitle = 0x01,
    HwMeetingContentTypeSummary = 0x02,
    HwMeetingContentTypeContent = 0x04
};

@interface HwMeeting : NSObject

@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *summary;
@property(nonatomic, copy) NSString *content;

- (HwMeeting *) initWithTitle:(NSString *)title
                      summary:(NSString *)summary
                      content:(NSString *)content;

@end

NS_ASSUME_NONNULL_END
