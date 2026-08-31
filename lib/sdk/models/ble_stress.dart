class BleStress {
  const BleStress({
    required this.index,
    required this.timeMs,
    required this.stress,
  });

  final int index;
  final int timeMs;
  final int stress;

  factory BleStress.fromMap(Map<dynamic, dynamic> map) {
    return BleStress(
      index: _intValue(map['index']),
      timeMs: _intValue(map['timeMs']),
      stress: _intValue(map['stress']),
    );
  }
}

int _intValue(Object? value) => value is num ? value.toInt() : 0;
