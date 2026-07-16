class BleSleep {
  const BleSleep({
    required this.index,
    required this.timeMs,
    this.deep = 0,
    this.light = 0,
    this.awake = 0,
    this.rem = 0,
  });

  final int index;
  final int timeMs;
  final int deep;
  final int light;
  final int awake;
  final int rem;

  factory BleSleep.fromMap(Map<dynamic, dynamic> map) {
    return BleSleep(
      index: map['index'] as int? ?? 0,
      timeMs: map['timeMs'] as int? ?? 0,
      deep: map['deep'] as int? ?? 0,
      light: map['light'] as int? ?? 0,
      awake: map['awake'] as int? ?? 0,
      rem: map['rem'] as int? ?? 0,
    );
  }
}
