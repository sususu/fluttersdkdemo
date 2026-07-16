//
//  HwPAI.h
//  Pods
//
//  Created by HuaWo on 2024/9/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwPAI : NSObject

@property(nonatomic, assign) NSTimeInterval time;
@property(nonatomic, assign) NSInteger totalValue;
@property(nonatomic, assign) NSInteger lowValue;
@property(nonatomic, assign) NSInteger medialValue;
@property(nonatomic, assign) NSInteger highValue;
@property(nonatomic, assign) NSInteger lowDuration;
@property(nonatomic, assign) NSInteger medialDuration;
@property(nonatomic, assign) NSInteger highDuration;
@end

NS_ASSUME_NONNULL_END
