class BleHealthDataCount {
  const BleHealthDataCount({
    required this.activityCount,
    required this.sleepCount,
    required this.heartrateCount,
    required this.hrfCount,
  });

  final int activityCount;
  final int sleepCount;
  final int heartrateCount;
  final int hrfCount;

  factory BleHealthDataCount.fromMap(Map<dynamic, dynamic> map) {
    return BleHealthDataCount(
      activityCount: map['activityCount'] as int? ?? 0,
      sleepCount: map['sleepCount'] as int? ?? 0,
      heartrateCount: map['heartrateCount'] as int? ?? 0,
      hrfCount: map['hrfCount'] as int? ?? 0,
    );
  }
}
