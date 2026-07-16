//
//  HwTimePoint.h
//  Pods
//
//  Created by HuaWo on 2022/6/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Represents a point in time, an hour, a minute
 */
@interface HwTimePoint : NSObject

@property(nonatomic, assign) NSInteger hour;
@property(nonatomic, assign) NSInteger minute;

- (HwTimePoint *) initWithHour:(NSInteger)hour
                        minute:(NSInteger)minute;

@end

NS_ASSUME_NONNULL_END
