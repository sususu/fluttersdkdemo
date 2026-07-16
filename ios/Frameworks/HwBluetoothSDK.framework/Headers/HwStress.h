//
//  HwStress.h
//  Pods
//
//  Created by HuaWo on 2022/8/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwStress : NSObject

@property(nonatomic, assign) NSUInteger index;
@property(nonatomic, assign) NSTimeInterval time;
@property(nonatomic, assign) NSInteger stress;

@end

NS_ASSUME_NONNULL_END
