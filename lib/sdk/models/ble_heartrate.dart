class BleHeartrate {
  const BleHeartrate({
    required this.index,
    required this.timeMs,
    required this.bpm,
  });

  final int index;
  final int timeMs;
  final int bpm;

  factory BleHeartrate.fromMap(Map<dynamic, dynamic> map) {
    return BleHeartrate(
      index: map['index'] as int? ?? 0,
      timeMs: map['timeMs'] as int? ?? 0,
      bpm: map['bpm'] as int? ?? 0,
    );
  }
}
