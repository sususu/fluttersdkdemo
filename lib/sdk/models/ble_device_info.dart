class BleDeviceInfo {
  const BleDeviceInfo({
    this.id,
    this.type,
    this.firmwareVersion,
    this.mac,
    this.bindState,
    this.language,
    this.battery,
    this.displayingWatchfaceId,
    this.watchfaceVersion,
    this.protocolVersion,
    this.mapUuid,
    this.mapAuthorized = false,
    this.features,
    this.supportedLanguages,
    this.recordFromDevice = false,
  });

  final String? id;
  final String? type;
  final String? firmwareVersion;
  final String? mac;
  final int? bindState;
  final int? language;
  final int? battery;
  final String? displayingWatchfaceId;
  final int? watchfaceVersion;
  final int? protocolVersion;
  final String? mapUuid;
  final bool mapAuthorized;
  final List<int>? features;
  final List<int>? supportedLanguages;
  final bool recordFromDevice;

  factory BleDeviceInfo.fromMap(Map<dynamic, dynamic> map) {
    return BleDeviceInfo(
      id: map['id'] as String?,
      type: map['type'] as String?,
      firmwareVersion: map['firmwareVersion'] as String?,
      mac: map['mac'] as String?,
      bindState: map['bindState'] as int?,
      language: map['language'] as int?,
      battery: map['battery'] as int?,
      displayingWatchfaceId: map['displayingWatchfaceId'] as String?,
      watchfaceVersion: map['watchfaceVersion'] as int?,
      protocolVersion: map['protocolVersion'] as int?,
      mapUuid: map['mapUuid'] as String?,
      mapAuthorized: map['mapAuthorized'] as bool? ?? false,
      recordFromDevice: map['recordFromDevice'] as bool? ?? false,
      features: (map['features'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      supportedLanguages: (map['supportedLanguages'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
    );
  }
}
