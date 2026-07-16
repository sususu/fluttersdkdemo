import 'models/ble_device.dart';

sealed class BleScanEvent {
  const BleScanEvent();
}

class BleScanStarted extends BleScanEvent {
  const BleScanStarted(this.success);
  final bool success;
}

class BleScanResult extends BleScanEvent {
  const BleScanResult(this.device);
  final BleDevice device;
}

class BleScanFinished extends BleScanEvent {
  const BleScanFinished(this.devices);
  final List<BleDevice> devices;
}

sealed class BleConnectionEvent {
  const BleConnectionEvent();
}

class BleConnectedEvent extends BleConnectionEvent {
  const BleConnectedEvent({this.deviceName, this.macAddress});
  final String? deviceName;
  final String? macAddress;
}

class BleDisconnectedEvent extends BleConnectionEvent {
  const BleDisconnectedEvent();
}
