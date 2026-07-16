import 'dart:async';

import 'package:flutter/services.dart';
import 'package:sdkdemo/sdk/hw_ble_events.dart';
import 'package:sdkdemo/sdk/models/bind_type.dart';
import 'package:sdkdemo/sdk/models/ble_activity.dart';
import 'package:sdkdemo/sdk/models/ble_bind_state.dart';
import 'package:sdkdemo/sdk/models/ble_device.dart';
import 'package:sdkdemo/sdk/models/ble_device_info.dart';
import 'package:sdkdemo/sdk/models/ble_health_data_count.dart';
import 'package:sdkdemo/sdk/models/ble_heartrate.dart';
import 'package:sdkdemo/sdk/models/ble_sleep.dart';
import 'package:sdkdemo/sdk/models/ble_unit.dart';
import 'package:sdkdemo/sdk/models/ble_user_info.dart';

/// Demo 内独立原生 SDK 桥接（不依赖 blesdk 插件）。
class HwBleSdk {
  HwBleSdk._();

  static final HwBleSdk instance = HwBleSdk._();

  static const _method = MethodChannel('sdkdemo/hw_ble');
  static const _scanEvents = EventChannel('sdkdemo/hw_ble/scan');
  static const _connectionEvents = EventChannel('sdkdemo/hw_ble/connection');

  Future<void> init({int maxMtu = 247}) async {
    await _method.invokeMethod<void>('init', {'maxMtu': maxMtu});
  }

  Future<void> destroy() async {
    await _method.invokeMethod<void>('destroy');
  }

  Future<String> getVersion() async {
    return await _method.invokeMethod<String>('getVersion') ?? '';
  }

  Stream<BleScanEvent> scanDevices({int timeoutMs = 8000}) {
    return _scanEvents.receiveBroadcastStream({'timeoutMs': timeoutMs}).map((
      raw,
    ) {
      final map = Map<dynamic, dynamic>.from(raw as Map);
      switch (map['event'] as String) {
        case 'scanStarted':
          return BleScanStarted(map['success'] as bool? ?? false);
        case 'scanResult':
          return BleScanResult(
            BleDevice.fromMap(map['device'] as Map),
          );
        case 'scanFinished':
          final devices = (map['devices'] as List<dynamic>? ?? [])
              .map((e) => BleDevice.fromMap(e as Map))
              .toList();
          return BleScanFinished(devices);
        default:
          throw StateError('Unknown scan event: ${map['event']}');
      }
    });
  }

  Future<void> stopScan() => _method.invokeMethod<void>('stopScan');

  Future<BleDevice> connect({
    String? macAddress,
    String? bleName,
    int timeoutSeconds = 30,
  }) async {
    final map = await _method.invokeMethod<Map<dynamic, dynamic>>('connect', {
      'macAddress': ?macAddress,
      'bleName': ?bleName,
      'timeoutSeconds': timeoutSeconds,
    });
    return BleDevice.fromMap(map ?? {});
  }

  Future<void> disconnect() => _method.invokeMethod<void>('disconnect');

  Future<bool> isConnected() async {
    return await _method.invokeMethod<bool>('isConnected') ?? false;
  }

  Stream<BleConnectionEvent> connectionEvents() {
    return _connectionEvents.receiveBroadcastStream().map((raw) {
      final map = Map<dynamic, dynamic>.from(raw as Map);
      final event = map['event'] as String?;
      if (event == 'connected') {
        return BleConnectedEvent(
          deviceName: map['deviceName'] as String?,
          macAddress: map['macAddress'] as String?,
        );
      }
      return const BleDisconnectedEvent();
    });
  }

  Future<void> startBind(BleBindType type) async {
    final method = switch (type) {
      BleBindType.normal => 'startBind',
      BleBindType.sifli => 'startSifliBind',
      BleBindType.qrCode => 'startQRCodeBind',
    };
    await _method.invokeMethod<void>(method);
  }

  Future<void> endBind() => _method.invokeMethod<void>('endBind');

  Future<void> setBind(bool bind) =>
      _method.invokeMethod<void>('setBind', {'bind': bind});

  Future<bool> isBind() async {
    return await _method.invokeMethod<bool>('isBind') ?? false;
  }

  Future<bool> isBonded() async {
    return await _method.invokeMethod<bool>('isBonded') ?? false;
  }

  Future<void> createBond() => _method.invokeMethod<void>('createBond');

  Future<void> removeBond() => _method.invokeMethod<void>('removeBond');

  Future<bool> getPairState() async {
    return await _method.invokeMethod<bool>('getPairState') ?? false;
  }

  Future<void> requestDeviceToPair() =>
      _method.invokeMethod<void>('requestDeviceToPair');

  Future<bool> getBtConnectionState() async {
    return await _method.invokeMethod<bool>('getBtConnectionState') ?? false;
  }

  Future<void> setBtSwitchWithAutoConnect({
    required bool on,
    required bool autoConnect,
  }) =>
      _method.invokeMethod<void>('setBtSwitchWithAutoConnect', {
        'on': on,
        'autoConnect': autoConnect,
      });

  Future<void> unbindDevice() => _method.invokeMethod<void>('unbindDevice');

  Future<void> removeConnectionCache() =>
      _method.invokeMethod<void>('removeConnectionCache');

  Future<void> setDeviceTime({
    required DateTime time,
    required bool use24HourFormat,
  }) =>
      _method.invokeMethod<void>('setDeviceTime', {
        'timeMs': time.millisecondsSinceEpoch,
        'use24HourFormat': use24HourFormat ? 1 : 0,
      });

  Future<void> setUserInfo(BleUserInfo userInfo) =>
      _method.invokeMethod<void>('setUserInfo', userInfo.toMap());

  Future<void> setUnit(BleUnit unit) =>
      _method.invokeMethod<void>('setUnit', {'unit': unit.value});

  Future<void> setLanguage(int languageCode) =>
      _method.invokeMethod<void>('setLanguage', {'language': languageCode});

  Future<BleDeviceInfo> getDeviceInfo() async {
    final map =
        await _method.invokeMethod<Map<dynamic, dynamic>>('getDeviceInfo');
    return BleDeviceInfo.fromMap(map ?? {});
  }

  Future<BleBindState> getBindState() async {
    final value = await _method.invokeMethod<int>('getBindState') ?? 0;
    return BleBindState.fromValue(value);
  }

  Future<BleHealthDataCount> getHealthDataCount() async {
    final map =
        await _method.invokeMethod<Map<dynamic, dynamic>>('getHealthDataCount');
    return BleHealthDataCount.fromMap(map ?? {});
  }

  Future<List<BleActivity>> getActivities(int activityCount) async {
    final list = await _method.invokeMethod<List<dynamic>>('getActivities', {
      'activityCount': activityCount,
    });
    return (list ?? [])
        .map((e) => BleActivity.fromMap(e as Map))
        .toList();
  }

  Future<void> deleteSports() => _method.invokeMethod<void>('deleteSports');

  Future<List<BleHeartrate>> getHeartrates() async {
    final list = await _method.invokeMethod<List<dynamic>>('getHeartrates');
    return (list ?? [])
        .map((e) => BleHeartrate.fromMap(e as Map))
        .toList();
  }

  Future<void> deleteHeartrates() =>
      _method.invokeMethod<void>('deleteHeartrates');

  Future<List<BleSleep>> getSleeps() async {
    final list = await _method.invokeMethod<List<dynamic>>('getSleeps');
    return (list ?? []).map((e) => BleSleep.fromMap(e as Map)).toList();
  }

  Future<void> deleteSleeps() => _method.invokeMethod<void>('deleteSleeps');
}
