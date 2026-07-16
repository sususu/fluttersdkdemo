class BleActivity {
  const BleActivity({
    required this.index,
    required this.timeMs,
    required this.step,
    required this.calorie,
    required this.staticCalorie,
    required this.distance,
    required this.duration,
    this.avgBpm = 0,
  });

  final int index;
  final int timeMs;
  final int step;
  final int calorie;
  final int staticCalorie;
  final int distance;
  final int duration;
  final int avgBpm;

  factory BleActivity.fromMap(Map<dynamic, dynamic> map) {
    return BleActivity(
      index: map['index'] as int? ?? 0,
      timeMs: map['timeMs'] as int? ?? 0,
      step: map['step'] as int? ?? 0,
      calorie: map['calorie'] as int? ?? 0,
      staticCalorie: map['staticCalorie'] as int? ?? 0,
      distance: map['distance'] as int? ?? 0,
      duration: map['duration'] as int? ?? 0,
      avgBpm: map['avgBpm'] as int? ?? 0,
    );
  }
}
