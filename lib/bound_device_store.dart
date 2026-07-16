import 'dart:convert';

import 'package:sdkdemo/sdk/sdk.dart';
import 'package:flutter/services.dart';

/// App 侧绑定信息本地存储（与 SDK 的 setBind 标记无关）。
/// 通过原生 SharedPreferences / UserDefaults 持久化。
class BoundDeviceStore {
  BoundDeviceStore._();

  static const _channel = MethodChannel('sdkdemo/bound_device');

  static Future<void> save({
    required String macAddress,
    String? name,
    BleDeviceInfo? deviceInfo,
  }) async {
    await _channel.invokeMethod<void>('save', {
      'macAddress': macAddress,
      'name': name ?? '',
      'deviceInfoJson': deviceInfo == null
          ? ''
          : jsonEncode(deviceInfoToMap(deviceInfo)),
    });
  }

  static Future<BoundDeviceRecord?> load() async {
    try {
      final map = await _channel.invokeMethod<Map<dynamic, dynamic>>('load');
      if (map == null) return null;
      final mac = map['macAddress'] as String? ?? '';
      if (mac.isEmpty) return null;
      final name = map['name'] as String?;
      BleDeviceInfo? info;
      final infoJson = map['deviceInfoJson'] as String?;
      if (infoJson != null && infoJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(infoJson) as Map<String, dynamic>;
          info = BleDeviceInfo.fromMap(decoded);
        } catch (_) {}
      }
      return BoundDeviceRecord(
        macAddress: mac,
        name: (name == null || name.trim().isEmpty) ? null : name,
        deviceInfo: info,
      );
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      await _channel.invokeMethod<void>('clear');
    } catch (_) {}
  }

  /// 供其它业务读取已缓存的设备信息。
  static Future<BleDeviceInfo?> loadDeviceInfo() async {
    final record = await load();
    return record?.deviceInfo;
  }

  static Map<String, dynamic> deviceInfoToMap(BleDeviceInfo info) {
    return {
      if (info.id != null) 'id': info.id,
      if (info.type != null) 'type': info.type,
      if (info.firmwareVersion != null) 'firmwareVersion': info.firmwareVersion,
      if (info.mac != null) 'mac': info.mac,
      if (info.bindState != null) 'bindState': info.bindState,
      if (info.language != null) 'language': info.language,
      if (info.battery != null) 'battery': info.battery,
      if (info.displayingWatchfaceId != null)
        'displayingWatchfaceId': info.displayingWatchfaceId,
      if (info.watchfaceVersion != null)
        'watchfaceVersion': info.watchfaceVersion,
      if (info.protocolVersion != null) 'protocolVersion': info.protocolVersion,
      if (info.mapUuid != null) 'mapUuid': info.mapUuid,
      'mapAuthorized': info.mapAuthorized,
      'recordFromDevice': info.recordFromDevice,
      if (info.features != null) 'features': info.features,
      if (info.supportedLanguages != null)
        'supportedLanguages': info.supportedLanguages,
    };
  }
}

class BoundDeviceRecord {
  const BoundDeviceRecord({
    required this.macAddress,
    this.name,
    this.deviceInfo,
  });

  final String macAddress;
  final String? name;
  final BleDeviceInfo? deviceInfo;
}
