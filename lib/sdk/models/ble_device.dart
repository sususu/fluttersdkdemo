class BleDevice {
  const BleDevice({
    required this.name,
    required this.macAddress,
    this.rssi,
    this.uuid,
  });

  final String? name;
  final String macAddress;
  final int? rssi;
  final String? uuid;

  factory BleDevice.fromMap(Map<dynamic, dynamic> map) {
    return BleDevice(
      name: map['name'] as String?,
      macAddress: map['macAddress'] as String? ?? '',
      rssi: map['rssi'] as int?,
      uuid: map['uuid'] as String?,
    );
  }
}
