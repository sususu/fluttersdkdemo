//
//  HwBluetoothCenter+Utils.h
//  HwBluetooth
//
//  Created by SuJiang on 2018/4/26.
//  Copyright © 2021年 huawo. All rights reserved.
//

#import "HwBluetoothCenter.h"
#import "HwBluetoothTask.h"
#import "HwBluetoothCallback.h"
#import "HwDeviceDefines.h"

@interface HwBluetoothCenter (Utils)

- (HwBluetoothTask *) sendData:(NSData *)data
                      priority:(HwBluetoothTaskPriority)priority
                  boolCallback:(HwBoolCallback)callback;

- (HwBluetoothTask *) sendData:(NSData *)data
                  boolCallback:(HwBoolCallback)callback;

- (HwBluetoothTask *) sendCollectionsCMDData:(NSData *)data
                                boolCallback:(HwBoolCallback)callback;

- (HwBluetoothTask *) sendData:(NSData *)data
                      priority:(HwBluetoothTaskPriority)priority
               integerCallback:(HwBCIntegerCallback)callback;

- (HwBluetoothTask *) sendData:(NSData *)data
               integerCallback:(HwBCIntegerCallback)callback;

- (HwBluetoothTask *) sendData:(NSData *)data
                      priority:(HwBluetoothTaskPriority)priority
                stringCallback:(HwStringCallback)callback;

- (HwBluetoothTask *) sendData:(NSData *)data
                stringCallback:(HwStringCallback)callback;

- (HwBluetoothTask *) sendBasicUnitData:(NSData *)data
                        integerCallback:(HwBCIntegerCallback)callback;

- (HwBluetoothTask *) sendBasicUnitData:(NSData *)data
                               priority:(HwBluetoothTaskPriority)priority
                        integerCallback:(HwBCIntegerCallback)callback;


- (int)dataToInt:(NSData *)data;
- (NSData *)intToData:(int)integer;

- (NSData *)intToData:(int)integer length:(NSUInteger)length;
- (int)dataToInt:(NSData *)data length:(NSUInteger)length;

- (long)dataToLong:(NSData *)data;
- (long)dataToLong:(NSData *)data from:(int)from to:(int)to;

+ (HwLanguage) getSystemLanguageType;

+ (NSData *)crcDataFromData:(NSData *)sendData total:(NSInteger)total;

#pragma mark - Varint Unsigned
+ (NSData *)dataWithUnsignedInt:(unsigned int)value;
+ (NSData *)dataWithUInt32:(UInt32)value;
+ (NSData *)dataWithUInt64:(UInt64)value;

+ (UInt32)unsignedDecode32FromBytes:(const void *)bytes offset:(UInt32 *)offset;
+ (UInt64)unsignedDecode64FromBytes:(const void *)bytes offset:(UInt32 *)offset;

#pragma mark -Varint Signed
+ (NSData *)dataWithInt:(int)value;
+ (NSData *)dataWithSInt32:(SInt32)value;
+ (NSData *)dataWithSInt64:(SInt64)value;

+ (SInt32)decode32FromBytes:(const void *)bytes offset:(UInt32 *)offset;
+ (SInt64)decode64FromBytes:(const void *)bytes offset:(UInt32 *)offset;

@end
