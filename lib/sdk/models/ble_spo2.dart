class BleSpo2 {
  const BleSpo2({
    required this.index,
    required this.timeMs,
    required this.spo2,
  });

  final int index;
  final int timeMs;
  final int spo2;

  factory BleSpo2.fromMap(Map<dynamic, dynamic> map) {
    return BleSpo2(
      index: _intValue(map['index']),
      timeMs: _intValue(map['timeMs']),
      spo2: _intValue(map['spo2']),
    );
  }
}

int _intValue(Object? value) => value is num ? value.toInt() : 0;
