//
//  HwBluetoothTask+PrivateExtension.h
//  CocoaLumberjack
//
//  Created by sujiang on 2020/4/9.
//

#import "HwBluetoothTask.h"

@interface HwBluetoothTask ()

- (void) start;

- (void) cancel;

- (void) dataStatePlain;

- (void) dataStateSending;

- (void) dataStateSent;

- (void) dataStateSendFailed;

- (void) dataStateReciving;

- (void) dataStateRecived;

- (void) dataStateReciveFailed;

- (void) dataStateTimeout;

- (void) refreshTimeout;

@end
