import 'dart:async';
import 'dart:typed_data';
import 'package:sdkdemo/sdk/models/ble_notification_contact.dart';

import 'package:flutter/services.dart';
import 'package:sdkdemo/sdk/hw_ble_events.dart';
import 'package:sdkdemo/sdk/models/bind_type.dart';
import 'package:sdkdemo/sdk/models/ble_activity.dart';
import 'package:sdkdemo/sdk/models/ble_alarm.dart';
import 'package:sdkdemo/sdk/models/ble_reminder_config.dart';
import 'package:sdkdemo/sdk/models/ble_bind_state.dart';
import 'package:sdkdemo/sdk/models/ble_device.dart';
import 'package:sdkdemo/sdk/models/ble_device_info.dart';
import 'package:sdkdemo/sdk/models/ble_health_data_count.dart';
import 'package:sdkdemo/sdk/models/ble_goal.dart';
import 'package:sdkdemo/sdk/models/ble_goal_type.dart';
import 'package:sdkdemo/sdk/models/ble_heartrate.dart';
import 'package:sdkdemo/sdk/models/ble_hrv.dart';
import 'package:sdkdemo/sdk/models/ble_sleep.dart';
import 'package:sdkdemo/sdk/models/ble_sleep_point.dart';
import 'package:sdkdemo/sdk/models/ble_workout.dart';
import 'package:sdkdemo/sdk/models/ble_spo2.dart';
import 'package:sdkdemo/sdk/models/ble_stress.dart';
import 'package:sdkdemo/sdk/models/ble_unit.dart';
import 'package:sdkdemo/sdk/models/ble_user_info.dart';

/// Demo 内独立原生 SDK 桥接（不依赖 blesdk 插件）。
class HwBleSdk {
  HwBleSdk._();

  static final HwBleSdk instance = HwBleSdk._();

  static const _method = MethodChannel('sdkdemo/hw_ble');
  static const _scanEvents = EventChannel('sdkdemo/hw_ble/scan');
  static const _connectionEvents = EventChannel('sdkdemo/hw_ble/connection');

  Future<List<BleNotificationSwitch>> getSocialSwitches() async {
    final rows = await _method.invokeMethod<List<dynamic>>('getSocialSwitches');
    if (rows == null) throw StateError('未返回通知开关列表');
    return rows
        .map((row) => BleNotificationSwitch.fromMap(row as Map))
        .toList();
  }

  Future<void> setSocialSwitch(int type, bool enabled) =>
      _method.invokeMethod<void>('setSocialSwitch', {
        'type': type,
        'enabled': enabled,
      });

  Future<void> setContacts(List<BleContact> contacts) =>
      _method.invokeMethod<void>('setContacts', {
        'contacts': contacts.map((c) => c.toMap()).toList(),
      });

  Future<void> setEmergencyContact(BleContact contact) =>
      _method.invokeMethod<void>('setEmergencyContact', contact.toMap());

  Future<Map<String, int>> getMusicStorage() async {
    final data = await _method.invokeMapMethod<String, dynamic>(
      'getMusicStorage',
    );
    if (data == null) throw StateError('未返回音乐容量');
    return {
      'availableKb': (data['availableKb'] as num).toInt(),
      'totalKb': (data['totalKb'] as num).toInt(),
    };
  }

  Future<List<Map<String, dynamic>>?> pickMusicFiles() async {
    final rows = await _method.invokeListMethod<dynamic>('pickMusicFiles');
    return rows?.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Stream<Map<String, dynamic>> musicTransferEvents() =>
      const EventChannel('sdkdemo/hw_ble/music').receiveBroadcastStream().map(
        (event) => Map<String, dynamic>.from(event as Map),
      );

  Future<void> pushMusicSifli() => _method.invokeMethod<void>('pushMusicSifli');
  Future<void> cancelMusicTransfer() =>
      _method.invokeMethod<void>('cancelMusicTransfer');

  Future<List<int>> getAlbumFileIds() async {
    final ids = await _method.invokeListMethod<dynamic>('getAlbumFileIds');
    if (ids == null) throw StateError('未返回相册位置列表');
    return ids.map((id) => (id as num).toInt()).toList();
  }

  Future<int?> pickAlbumImages() =>
      _method.invokeMethod<int>('pickAlbumImages');

  Stream<Map<String, dynamic>> albumTransferEvents() =>
      const EventChannel('sdkdemo/hw_ble/album').receiveBroadcastStream().map(
        (event) => Map<String, dynamic>.from(event as Map),
      );

  Future<void> pushAlbumSifli({required int width, required int height}) =>
      _method.invokeMethod<void>('pushAlbumSifli', {
        'width': width,
        'height': height,
      });
  Future<void> cancelAlbumTransfer() =>
      _method.invokeMethod<void>('cancelAlbumTransfer');

  Future<Map<String, dynamic>> getDeviceGpsStatus() async {
    final data = await _method.invokeMapMethod<String, dynamic>('getDeviceGpsStatus');
    if (data == null) throw StateError('未返回 GPS 状态');
    return data;
  }

  Stream<Map<String, dynamic>> agpsUpdateEvents() =>
      const EventChannel('sdkdemo/hw_ble/agps').receiveBroadcastStream().map(
        (event) => Map<String, dynamic>.from(event as Map),
      );
  Future<void> updateAgps() => _method.invokeMethod<void>('updateAgps');
  Future<void> cancelAgpsUpdate() => _method.invokeMethod<void>('cancelAgpsUpdate');

  Future<Map<String, dynamic>> refreshOtaInfo() async {
    final data = await _method.invokeMapMethod<String, dynamic>('refreshOtaInfo');
    if (data == null) throw StateError('未返回设备信息');
    return data;
  }
  Future<Map<String, dynamic>> checkOta() async {
    final data = await _method.invokeMapMethod<String, dynamic>('checkOta');
    if (data == null) throw StateError('未返回升级信息');
    return data;
  }
  Future<void> startOta() => _method.invokeMethod<void>('startOta');
  Future<void> cancelOta() => _method.invokeMethod<void>('cancelOta');
  Stream<Map<String, dynamic>> otaEvents() =>
      const EventChannel('sdkdemo/hw_ble/ota').receiveBroadcastStream().map(
        (event) => Map<String, dynamic>.from(event as Map),
      );

  Future<List<Map<String, dynamic>>> getOnlineWatchfaces() async {
    final rows = await _method.invokeListMethod<dynamic>('getOnlineWatchfaces');
    if (rows == null) throw StateError('未返回在线表盘列表');
    return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }
  Future<void> installOnlineWatchface(String id) =>
      _method.invokeMethod<void>('installOnlineWatchface', {'id': id});
  Future<void> cancelWatchfaceTransfer() => _method.invokeMethod<void>('cancelWatchfaceTransfer');
  Stream<Map<String, dynamic>> watchfaceTransferEvents() =>
      const EventChannel('sdkdemo/hw_ble/watchface').receiveBroadcastStream().map(
        (event) => Map<String, dynamic>.from(event as Map),
      );

  Future<Uint8List?> pickCustomWatchfaceBackground() =>
      _method.invokeMethod<Uint8List>('pickCustomWatchfaceBackground');
  Future<Uint8List> previewCustomWatchface(Map<String, dynamic> config) async {
    final png = await _method.invokeMethod<Uint8List>('previewCustomWatchface', config);
    if (png == null) throw StateError('未返回表盘预览');
    return png;
  }
  Future<void> pushCustomWatchface(Map<String, dynamic> config) =>
      _method.invokeMethod<void>('pushCustomWatchface', config);
  Stream<Map<String, dynamic>> customWatchfaceEvents() =>
      const EventChannel('sdkdemo/hw_ble/customWatchface').receiveBroadcastStream().map(
        (event) => Map<String, dynamic>.from(event as Map),
      );

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
          return BleScanResult(BleDevice.fromMap(map['device'] as Map));
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
  }) => _method.invokeMethod<void>('setBtSwitchWithAutoConnect', {
    'on': on,
    'autoConnect': autoConnect,
  });

  Future<void> unbindDevice() => _method.invokeMethod<void>('unbindDevice');

  Future<void> removeConnectionCache() =>
      _method.invokeMethod<void>('removeConnectionCache');

  Future<void> setDeviceTime({
    required DateTime time,
    required bool use24HourFormat,
  }) => _method.invokeMethod<void>('setDeviceTime', {
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
    final map = await _method.invokeMethod<Map<dynamic, dynamic>>(
      'getDeviceInfo',
    );
    return BleDeviceInfo.fromMap(map ?? {});
  }

  Future<BleBindState> getBindState() async {
    final value = await _method.invokeMethod<int>('getBindState') ?? 0;
    return BleBindState.fromValue(value);
  }

  Future<BleHealthDataCount> getHealthDataCount() async {
    final map = await _method.invokeMethod<Map<dynamic, dynamic>>(
      'getHealthDataCount',
    );
    return BleHealthDataCount.fromMap(map ?? {});
  }

  Future<void> setGoal(BleGoalType type, int value) => _method
      .invokeMethod<void>('setGoal', {'type': type.value, 'value': value});

  Future<BleGoal> getGoals() async {
    final map = await _method.invokeMethod<Map<dynamic, dynamic>>('getGoals');
    if (map == null) {
      throw StateError('getGoals returned empty result');
    }
    return BleGoal.fromMap(map);
  }

  Future<List<BleAlarm>> getAlarms() async {
    final list = await _method.invokeMethod<List<dynamic>>('getAlarms');
    return (list ?? []).map((e) => BleAlarm.fromMap(e as Map)).toList();
  }

  Future<void> addDemoAlarm() => _method.invokeMethod<void>('addDemoAlarm');

  Future<int> addJlDemoAlarm() async {
    final alarmId = await _method.invokeMethod<int>('addJlDemoAlarm');
    if (alarmId == null) {
      throw StateError('addJlDemoAlarm returned empty alarm ID');
    }
    return alarmId;
  }

  Future<void> deleteAllAlarms() =>
      _method.invokeMethod<void>('deleteAllAlarms');

  Future<BleReminderConfig> getSedentaryReminder() =>
      _getReminderConfig('getSedentaryReminder');

  /// Enables weekdays 09:00–18:00, every 3600 seconds (iOS demo).
  Future<void> setDemoSedentaryReminder() =>
      _method.invokeMethod<void>('setDemoSedentaryReminder');

  Future<BleReminderConfig> getDrinkWaterReminder() =>
      _getReminderConfig('getDrinkWaterReminder');

  /// Enables every day 08:00–20:00, every 3600 seconds (iOS demo).
  Future<void> setDemoDrinkWaterReminder() =>
      _method.invokeMethod<void>('setDemoDrinkWaterReminder');

  Future<BleReminderConfig> getHandwashingReminder() =>
      _getReminderConfig('getHandwashingReminder');

  /// Enables every day 08:00–22:00, every 7200 seconds (iOS demo).
  Future<void> setDemoHandwashingReminder() =>
      _method.invokeMethod<void>('setDemoHandwashingReminder');

  Future<BleReminderConfig> _getReminderConfig(String method) async {
    final map = await _method.invokeMethod<Map<dynamic, dynamic>>(method);
    if (map == null) throw StateError('$method returned empty result');
    return BleReminderConfig.fromMap(map);
  }

  Future<List<BleActivity>> getActivities(int activityCount) async {
    final list = await _method.invokeMethod<List<dynamic>>('getActivities', {
      'activityCount': activityCount,
    });
    return (list ?? []).map((e) => BleActivity.fromMap(e as Map)).toList();
  }

  Future<void> deleteSports() => _method.invokeMethod<void>('deleteSports');

  Future<List<BleHeartrate>> getHeartrates() async {
    final list = await _method.invokeMethod<List<dynamic>>('getHeartrates');
    return (list ?? []).map((e) => BleHeartrate.fromMap(e as Map)).toList();
  }

  Future<void> deleteHeartrates() =>
      _method.invokeMethod<void>('deleteHeartrates');

  Future<List<BleSleep>> getSleeps() async {
    final list = await _method.invokeMethod<List<dynamic>>('getSleeps');
    return (list ?? []).map((e) => BleSleep.fromMap(e as Map)).toList();
  }

  Future<List<BleActivity>> getActivitiesV2() async {
    final list = await _method.invokeMethod<List<dynamic>>('getActivitiesV2');
    if (list == null) throw StateError('getActivitiesV2 returned empty result');
    return list.map((e) => BleActivity.fromMap(e as Map)).toList();
  }

  Future<List<BleSleep>> getSleepsV2() async {
    final list = await _method.invokeMethod<List<dynamic>>('getSleepsV2');
    return (list ?? []).map((e) => BleSleep.fromMap(e as Map)).toList();
  }

  Future<List<BleHeartrate>> getHeartratesV2() async {
    final list = await _method.invokeMethod<List<dynamic>>('getHeartratesV2');
    if (list == null) throw StateError('getHeartratesV2 returned empty result');
    return list.map((e) => BleHeartrate.fromMap(e as Map)).toList();
  }

  Future<List<BleSpo2>> getSpo2sV2() async {
    final list = await _method.invokeMethod<List<dynamic>>('getSpo2sV2');
    if (list == null) throw StateError('getSpo2sV2 returned empty result');
    return list.map((e) => BleSpo2.fromMap(e as Map)).toList();
  }

  Future<List<BleStress>> getStressesV2() async {
    final list = await _method.invokeMethod<List<dynamic>>('getStressesV2');
    if (list == null) throw StateError('getStressesV2 returned empty result');
    return list.map((e) => BleStress.fromMap(e as Map)).toList();
  }

  /// Jieli sleep points; getSleepsV2 remains the Android summary API.
  Future<List<BleSleepPoint>> getSleepPointsV2() async {
    final list = await _method.invokeMethod<List<dynamic>>('getSleepPointsV2');
    if (list == null)
      throw StateError('getSleepPointsV2 returned empty result');
    return list.map((e) => BleSleepPoint.fromMap(e as Map)).toList();
  }

  Future<List<BleWorkout>> getWorkoutsV2() async {
    final list = await _method.invokeMethod<List<dynamic>>('getWorkoutsV2');
    if (list == null) throw StateError('getWorkoutsV2 returned empty result');
    return list.map((e) => BleWorkout.fromMap(e as Map)).toList();
  }

  Future<List<BleHrv>> getHrvsV2() async {
    final list = await _method.invokeMethod<List<dynamic>>('getHrvsV2');
    return (list ?? []).map((e) => BleHrv.fromMap(e as Map)).toList();
  }

  Future<void> deleteSleeps() => _method.invokeMethod<void>('deleteSleeps');

  Future<void> deleteSpo2s() => _method.invokeMethod<void>('deleteSpo2s');

  Future<void> deleteStresses() => _method.invokeMethod<void>('deleteStresses');

  Future<void> deleteWorkouts() => _method.invokeMethod<void>('deleteWorkouts');
}
