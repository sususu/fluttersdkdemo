/// A Jieli sleep state transition, not a duration summary.
class BleSleepPoint {
  BleSleepPoint.fromMap(Map<dynamic, dynamic> map)
    : timeMs = (map['timeMs'] as num).toInt(),
      status = (map['status'] as num).toInt();

  final int timeMs;
  final int status;

  String get statusDescription => switch (status) {
    0 => '深睡',
    1 => '浅睡',
    2 => '清醒',
    3 => '准备入睡',
    5 => 'REM',
    0x10 => '进入睡眠',
    0x11 || 0x12 => '退出睡眠',
    _ => '未知状态（$status）',
  };
}
