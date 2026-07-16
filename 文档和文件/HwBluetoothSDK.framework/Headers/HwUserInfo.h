//
//  HwUserInfo.h
//  Pods
//
//  Created by HuaWo on 2022/6/16.
//

#import <Foundation/Foundation.h>
#import "HwDeviceDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface HwUserInfo : NSObject

@property(nonatomic, copy) NSString *Id;

@property(nonatomic, assign) HwSex gender;
@property(nonatomic, assign) NSInteger age;
/**
 cm
 */
@property(nonatomic, assign) NSInteger height;
/**
 0.1KG
 */
@property(nonatomic, assign) NSInteger weight;

@property(nonatomic, assign) NSInteger birthdayYear;
@property(nonatomic, assign) NSInteger birthdayMonth;
@property(nonatomic, assign) NSInteger birthdayDay;

@end

NS_ASSUME_NONNULL_END
