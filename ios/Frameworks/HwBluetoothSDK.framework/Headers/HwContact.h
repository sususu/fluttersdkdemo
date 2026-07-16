//
//  HwContact.h
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HwContact : NSObject

//索引
@property(nonatomic, assign) int contactIndex;
@property(nonatomic, copy) NSString *contactName;
@property(nonatomic, copy) NSString *contactPhone;

@property(nonatomic, strong) UIColor *tintColor;

- (NSData *) toData;
- (id) initWithData:(NSData *)data;

- (BOOL) hasColor;

@end

NS_ASSUME_NONNULL_END
