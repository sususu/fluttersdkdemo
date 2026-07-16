//
//  HwQrCard.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2022/12/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwQrCard : NSObject

@property(nonatomic, assign) NSInteger Id;
@property(nonatomic, strong) NSString *content;
@property(nonatomic, strong) NSString *name;

- (HwQrCard *) initWithData:(NSData *)data;

- (NSData *) toData;

@end

NS_ASSUME_NONNULL_END
