//
//  HwKeyChainUtils.h
//  HwBluetoothSDK
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwKeyChainUtils : NSObject

+ (HwKeyChainUtils *)sharedInstance;

- (void)setDictionary:(NSDictionary *)dict forKey:(NSString *)key;
- (NSDictionary *)getDictionaryForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
