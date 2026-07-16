//
//  HwHealthAnalysisResult.h
//  HwBluetoothSDK
//
//  Created by HuaWo on 2025/3/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwHealthAnalysisResult : NSObject

@property(nonatomic, copy) NSString *step;
@property(nonatomic, copy) NSString *heartRate;
@property(nonatomic, copy) NSString *spO2;
@property(nonatomic, copy) NSString *stress;
@property(nonatomic, copy) NSString *bp;
@property(nonatomic, copy) NSString *sleep;
@property(nonatomic, copy) NSString *PAI;
@property(nonatomic, copy) NSString *weight;
@property(nonatomic, copy) NSString *summary;

@end

NS_ASSUME_NONNULL_END
