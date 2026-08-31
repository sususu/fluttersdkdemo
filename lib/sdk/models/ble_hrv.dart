class BleHrv {
  const BleHrv({
    required this.index,
    required this.timeMs,
    required this.fatigue,
  });

  final int index;
  final int timeMs;
  final int fatigue;

  factory BleHrv.fromMap(Map<dynamic, dynamic> map) {
    return BleHrv(
      index: _intValue(map['index']),
      timeMs: _intValue(map['timeMs']),
      fatigue: _intValue(map['fatigue']),
    );
  }
}

int _intValue(Object? value) => value is num ? value.toInt() : 0;
