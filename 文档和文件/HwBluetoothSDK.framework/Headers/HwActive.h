//
//  HwActive.h
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HwActiveState) {
    HwActiveStateOffHand = 0x00,
    HwActiveStateActive,
    HwActiveStateInactive
};

/**
 HwActive: How many times have you been active
 */
@interface HwActive : NSObject

@property(nonatomic, assign) NSUInteger index;
/**
 Active at time
 */
@property(nonatomic, assign) NSTimeInterval time;
/**
 Active data state
 */
@property(nonatomic, assign) HwActiveState state;

@end

NS_ASSUME_NONNULL_END
